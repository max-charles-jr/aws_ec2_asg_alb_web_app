# General Configuration
aws_region   = "us-east-1"
environment  = "prod"
project_name = "myapp"

# Network Configuration
vpc_id = "vpc-abcdef0123456789a" # Replace with your PROD VPC ID
subnet_ids = [
  "subnet-abcdef0123456789a", # Replace with your PROD subnet IDs
  "subnet-abcdef0123456789b",
  "subnet-abcdef0123456789c" # More subnets for production
]

# EC2 Configuration
instance_type    = "t3.medium"             # Larger instances for production
ami_id           = "ami-0c55b159cbfafe1f0" # Replace with your AMI ID
key_name         = "prod-keypair"
allowed_ssh_cidr = ["10.2.0.0/16"] # Restrict SSH access

# Auto Scaling Configuration
asg_desired_capacity      = 2
asg_min_size              = 2
asg_max_size              = 4
health_check_grace_period = 300
health_check_type         = "EC2" # Consider "ELB" if using load balancer

# Monitoring Configuration
cloudwatch_log_retention_days = 30 # Keep logs longer in production
enable_monitoring             = true
enable_cloudwatch_alarms      = true
cpu_alarm_threshold           = 70 # Lower threshold for production alerts

# Additional Security Group Rules (optional)
additional_security_group_rules = [
  {
    type        = "ingress"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["10.2.0.0/16"]
    description = "Allow custom app port from production network"
  }
]

# Custom User Data (optional)
user_data_script = ""

# Additional Tags
additional_tags = {
  CostCenter  = "Production"
  Owner       = "DevOps Team"
  Backup      = "true"
  Compliance  = "PCI-DSS"
  Criticality = "High"
}
