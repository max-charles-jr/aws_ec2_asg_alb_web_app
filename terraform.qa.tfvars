# General Configuration
aws_region   = "us-east-1"
environment  = "qa"
project_name = "myapp"

# Network Configuration
vpc_id = "vpc-0987654321fedcba0" # Replace with your QA VPC ID
subnet_ids = [
  "subnet-0987654321fedcba0", # Replace with your QA subnet IDs
  "subnet-0987654321fedcba1"
]

# EC2 Configuration
instance_type    = "t3.small"              # Slightly larger for QA
ami_id           = "ami-0c55b159cbfafe1f0" # Replace with your AMI ID
key_name         = "qa-keypair"
allowed_ssh_cidr = ["10.1.0.0/16"]

# Auto Scaling Configuration
asg_desired_capacity      = 2
asg_min_size              = 2
asg_max_size              = 4
health_check_grace_period = 300
health_check_type         = "EC2"

# Monitoring Configuration
cloudwatch_log_retention_days = 14 # Keep logs longer in QA
enable_monitoring             = true
enable_cloudwatch_alarms      = true
cpu_alarm_threshold           = 75

# Additional Security Group Rules (optional)
additional_security_group_rules = [
  {
    type        = "ingress"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["10.1.0.0/16"]
    description = "Allow custom app port from QA network"
  }
]

# Custom User Data (optional)
user_data_script = ""

# Additional Tags
additional_tags = {
  CostCenter = "Engineering"
  Owner      = "QA Team"
  Backup     = "true"
}
