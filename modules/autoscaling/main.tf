# Security Group for EC2 instances
resource "aws_security_group" "asg_sg" {
  name_prefix = "${var.project_name}-${var.environment}-asg-"
  description = "Security group for Auto Scaling Group instances"
  vpc_id      = var.vpc_id

  # Allow HTTP traffic
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow HTTP inbound"
  }

  # Allow HTTPS traffic
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow HTTPS inbound"
  }

  # Allow SSH (optional - restrict CIDR blocks)
  dynamic "ingress" {
    for_each = length(var.allowed_ssh_cidr) > 0 ? [1] : []
    content {
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = var.allowed_ssh_cidr
      description = "Allow SSH inbound"
    }
  }

  # Additional custom security group rules
  dynamic "ingress" {
    for_each = [for rule in var.additional_security_group_rules : rule if rule.type == "ingress"]
    content {
      from_port   = ingress.value.from_port
      to_port     = ingress.value.to_port
      protocol    = ingress.value.protocol
      cidr_blocks = ingress.value.cidr_blocks
      description = ingress.value.description
    }
  }

  # Allow all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound"
  }

  tags = merge(
    {
      Name        = "${var.project_name}-${var.environment}-asg-sg"
      Environment = var.environment
      Project     = var.project_name
      ManagedBy   = "Terraform"
    },
    var.additional_tags
  )

  lifecycle {
    create_before_destroy = true
  }
}

# IAM Role for EC2 instances
resource "aws_iam_role" "ec2_role" {
  name_prefix = "${var.project_name}-${var.environment}-ec2-role-"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = merge(
    {
      Name        = "${var.project_name}-${var.environment}-ec2-role"
      Environment = var.environment
      Project     = var.project_name
      ManagedBy   = "Terraform"
    },
    var.additional_tags
  )
}

# Attach policies to IAM role
resource "aws_iam_role_policy_attachment" "ssm_managed_instance" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy_attachment" "cloudwatch_agent" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

# IAM Instance Profile
resource "aws_iam_instance_profile" "ec2_profile" {
  name_prefix = "${var.project_name}-${var.environment}-ec2-profile-"
  role        = aws_iam_role.ec2_role.name

  tags = merge(
    {
      Name        = "${var.project_name}-${var.environment}-ec2-profile"
      Environment = var.environment
      Project     = var.project_name
      ManagedBy   = "Terraform"
    },
    var.additional_tags
  )
}

# Default User Data Script
locals {
  default_user_data = <<-EOF
              #!/bin/bash
              set -e
              
              # Update system packages
              yum update -y
              
              # Install CloudWatch agent
              wget https://s3.amazonaws.com/amazoncloudwatch-agent/amazon_linux/amd64/latest/amazon-cloudwatch-agent.rpm
              rpm -U ./amazon-cloudwatch-agent.rpm
              
              # Configure CloudWatch logs
              cat > /opt/aws/amazon-cloudwatch-agent/etc/config.json <<CONFIG
              {
                "logs": {
                  "logs_collected": {
                    "files": {
                      "collect_list": [
                        {
                          "file_path": "/var/log/messages",
                          "log_group_name": "/aws/ec2/${var.project_name}-${var.environment}",
                          "log_stream_name": "{instance_id}/messages"
                        },
                        {
                          "file_path": "/var/log/cloud-init-output.log",
                          "log_group_name": "/aws/ec2/${var.project_name}-${var.environment}",
                          "log_stream_name": "{instance_id}/cloud-init"
                        }
                      ]
                    }
                  }
                }
              }
              CONFIG
              
              # Start CloudWatch agent
              /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
                -a fetch-config \
                -m ec2 \
                -s \
                -c file:/opt/aws/amazon-cloudwatch-agent/etc/config.json
              
              echo "Instance initialized successfully for ${var.environment} environment" > /var/log/startup.log
              EOF

  user_data = var.user_data_script != "" ? var.user_data_script : local.default_user_data
}

# Launch Template
resource "aws_launch_template" "asg_lt" {
  name_prefix   = "${var.project_name}-${var.environment}-lt-"
  image_id      = var.ami_id
  instance_type = var.instance_type
  key_name      = var.key_name != "" ? var.key_name : null

  iam_instance_profile {
    name = aws_iam_instance_profile.ec2_profile.name
  }

  vpc_security_group_ids = [aws_security_group.asg_sg.id]

  user_data = base64encode(local.user_data)

  monitoring {
    enabled = var.enable_monitoring
  }

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }

  tag_specifications {
    resource_type = "instance"
    tags = merge(
      {
        Name        = "${var.project_name}-${var.environment}-asg-instance"
        Environment = var.environment
        Project     = var.project_name
        ManagedBy   = "Terraform"
      },
      var.additional_tags
    )
  }

  tag_specifications {
    resource_type = "volume"
    tags = merge(
      {
        Name        = "${var.project_name}-${var.environment}-asg-volume"
        Environment = var.environment
        Project     = var.project_name
        ManagedBy   = "Terraform"
      },
      var.additional_tags
    )
  }

  lifecycle {
    create_before_destroy = true
  }

  tags = merge(
    {
      Name        = "${var.project_name}-${var.environment}-launch-template"
      Environment = var.environment
      Project     = var.project_name
      ManagedBy   = "Terraform"
    },
    var.additional_tags
  )
}

# Auto Scaling Group
resource "aws_autoscaling_group" "asg" {
  name_prefix         = "${var.project_name}-${var.environment}-asg-"
  vpc_zone_identifier = var.subnet_ids

  desired_capacity = var.asg_desired_capacity
  min_size         = var.asg_min_size
  max_size         = var.asg_max_size

  health_check_type         = var.health_check_type
  health_check_grace_period = var.health_check_grace_period

  launch_template {
    id      = aws_launch_template.asg_lt.id
    version = "$Latest"
  }

  enabled_metrics = [
    "GroupDesiredCapacity",
    "GroupInServiceInstances",
    "GroupMaxSize",
    "GroupMinSize",
    "GroupPendingInstances",
    "GroupStandbyInstances",
    "GroupTerminatingInstances",
    "GroupTotalInstances"
  ]

  instance_refresh {
    strategy = "Rolling"
    preferences {
      min_healthy_percentage = 50
    }
  }

  tag {
    key                 = "Name"
    value               = "${var.project_name}-${var.environment}-asg"
    propagate_at_launch = false
  }

  tag {
    key                 = "Environment"
    value               = var.environment
    propagate_at_launch = true
  }

  tag {
    key                 = "Project"
    value               = var.project_name
    propagate_at_launch = true
  }

  tag {
    key                 = "ManagedBy"
    value               = "Terraform"
    propagate_at_launch = true
  }

  dynamic "tag" {
    for_each = var.additional_tags
    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    }
  }

  lifecycle {
    create_before_destroy = true
    ignore_changes        = [desired_capacity]
  }
}

# CloudWatch Log Group
resource "aws_cloudwatch_log_group" "asg_logs" {
  name              = "/aws/ec2/${var.project_name}-${var.environment}"
  retention_in_days = var.cloudwatch_log_retention_days

  tags = merge(
    {
      Name        = "${var.project_name}-${var.environment}-logs"
      Environment = var.environment
      Project     = var.project_name
      ManagedBy   = "Terraform"
    },
    var.additional_tags
  )
}

# CloudWatch Alarms
resource "aws_cloudwatch_metric_alarm" "asg_cpu_high" {
  count = var.enable_cloudwatch_alarms ? 1 : 0

  alarm_name          = "${var.project_name}-${var.environment}-asg-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 300
  statistic           = "Average"
  threshold           = var.cpu_alarm_threshold
  alarm_description   = "This metric monitors ec2 cpu utilization in ${var.environment}"

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.asg.name
  }

  tags = merge(
    {
      Name        = "${var.project_name}-${var.environment}-cpu-alarm"
      Environment = var.environment
      Project     = var.project_name
      ManagedBy   = "Terraform"
    },
    var.additional_tags
  )
}

resource "aws_cloudwatch_metric_alarm" "asg_unhealthy_instances" {
  count = var.enable_cloudwatch_alarms ? 1 : 0

  alarm_name          = "${var.project_name}-${var.environment}-asg-unhealthy"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 1
  metric_name         = "GroupInServiceInstances"
  namespace           = "AWS/AutoScaling"
  period              = 60
  statistic           = "Average"
  threshold           = var.asg_min_size
  alarm_description   = "Alert when instances are unhealthy in ${var.environment}"
  treat_missing_data  = "notBreaching"

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.asg.name
  }

  tags = merge(
    {
      Name        = "${var.project_name}-${var.environment}-unhealthy-alarm"
      Environment = var.environment
      Project     = var.project_name
      ManagedBy   = "Terraform"
    },
    var.additional_tags
  )
}
