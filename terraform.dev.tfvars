# General Configuration
aws_region   = "us-east-1"
environment  = "dev"
project_name = "myapp"

# Network Configuration
vpc_id = "vpc-0123456789abcdef0" # Replace with your DEV VPC ID
subnet_ids = [
  "subnet-0123456789abcdef0", # Replace with your DEV subnet IDs
  "subnet-0123456789abcdef1"
]

# EC2 Configuration
instance_type    = "t3.micro"
ami_id           = "ami-0c55b159cbfafe1f0" # Replace with your AMI ID
key_name         = "dev-keypair"
allowed_ssh_cidr = ["10.0.0.0/8"]

# Auto Scaling Configuration
asg_desired_capacity      = 2
asg_min_size              = 2
asg_max_size              = 4
health_check_grace_period = 300
health_check_type         = "EC2"

# Monitoring Configuration
cloudwatch_log_retention_days = 7
enable_monitoring             = true
enable_cloudwatch_alarms      = true
cpu_alarm_threshold           = 80

# Additional Security Group Rules (optional)
additional_security_group_rules = [
  {
    type        = "ingress"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/8"]
    description = "Allow custom app port from internal network"
  }
]

# Custom User Data (optional - leave empty to use default)
user_data_script = ""

# Additional Tags
additional_tags = {
  CostCenter = "Engineering"
  Owner      = "DevOps Team"
  Backup     = "true"
}
