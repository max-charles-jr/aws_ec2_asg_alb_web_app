terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Environment = var.environment
      Project     = var.project_name
      ManagedBy   = "Terraform"
      DeployedBy  = "GitHub-Actions"
    }
  }
}

# Call the autoscaling module
module "autoscaling" {
  source = "./modules/autoscaling"

  # General Configuration
  aws_region   = var.aws_region
  environment  = var.environment
  project_name = var.project_name

  # Network Configuration
  vpc_id     = var.vpc_id
  subnet_ids = var.subnet_ids

  # EC2 Configuration
  instance_type    = var.instance_type
  ami_id           = var.ami_id
  key_name         = var.key_name
  allowed_ssh_cidr = var.allowed_ssh_cidr

  # Auto Scaling Configuration
  asg_desired_capacity      = var.asg_desired_capacity
  asg_min_size              = var.asg_min_size
  asg_max_size              = var.asg_max_size
  health_check_grace_period = var.health_check_grace_period
  health_check_type         = var.health_check_type

  # Monitoring Configuration
  cloudwatch_log_retention_days = var.cloudwatch_log_retention_days
  enable_monitoring             = var.enable_monitoring
  enable_cloudwatch_alarms      = var.enable_cloudwatch_alarms
  cpu_alarm_threshold           = var.cpu_alarm_threshold

  # Additional Configuration
  additional_security_group_rules = var.additional_security_group_rules
  user_data_script                = var.user_data_script
  additional_tags                 = var.additional_tags
}
