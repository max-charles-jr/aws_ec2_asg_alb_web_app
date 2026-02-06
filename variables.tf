variable "aws_region" {
  description = "AWS region for resources"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, qa, prod)"
  type        = string

  validation {
    condition     = contains(["dev", "qa", "prod"], lower(var.environment))
    error_message = "Environment must be dev, qa, or prod."
  }
}

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where resources will be created"
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs for Auto Scaling Group"
  type        = list(string)

  validation {
    condition     = length(var.subnet_ids) >= 2
    error_message = "At least 2 subnet IDs are required for high availability."
  }
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
}

variable "ami_id" {
  description = "AMI ID for EC2 instances"
  type        = string
}

variable "key_name" {
  description = "SSH key pair name"
  type        = string
  default     = ""
}

variable "allowed_ssh_cidr" {
  description = "CIDR blocks allowed to SSH"
  type        = list(string)
  default     = []
}

variable "asg_desired_capacity" {
  description = "Desired number of instances in ASG"
  type        = number
}

variable "asg_min_size" {
  description = "Minimum number of instances in ASG"
  type        = number
}

variable "asg_max_size" {
  description = "Maximum number of instances in ASG"
  type        = number
}

variable "health_check_grace_period" {
  description = "Time in seconds after instance comes into service before checking health"
  type        = number
  default     = 300
}

variable "health_check_type" {
  description = "Type of health check (EC2 or ELB)"
  type        = string
  default     = "EC2"

  validation {
    condition     = contains(["EC2", "ELB"], var.health_check_type)
    error_message = "Health check type must be EC2 or ELB."
  }
}

variable "cloudwatch_log_retention_days" {
  description = "CloudWatch log retention in days"
  type        = number
}

variable "enable_monitoring" {
  description = "Enable detailed monitoring"
  type        = bool
  default     = true
}

variable "enable_cloudwatch_alarms" {
  description = "Enable CloudWatch alarms"
  type        = bool
  default     = true
}

variable "cpu_alarm_threshold" {
  description = "CPU utilization threshold for alarm"
  type        = number
  default     = 80
}

variable "additional_security_group_rules" {
  description = "Additional security group rules"
  type = list(object({
    type        = string
    from_port   = number
    to_port     = number
    protocol    = string
    cidr_blocks = list(string)
    description = string
  }))
  default = []
}

variable "user_data_script" {
  description = "Custom user data script (optional)"
  type        = string
  default     = ""
}

variable "additional_tags" {
  description = "Additional tags to apply to resources"
  type        = map(string)
  default     = {}
}
