# Auto Scaling Group Module

This module creates an Auto Scaling Group with EC2 instances, including all necessary supporting resources.

## Features

- Auto Scaling Group with configurable capacity
- Launch Template with custom user data
- Security Group with configurable rules
- IAM Role and Instance Profile
- CloudWatch Logs integration
- CloudWatch Alarms for monitoring
- Support for multiple environments

## Usage
```hcl
module "autoscaling" {
  source = "../../modules/autoscaling"

  aws_region   = "us-east-1"
  environment  = "dev"
  project_name = "myapp"
  
  vpc_id     = "vpc-xxxxxxxxx"
  subnet_ids = ["subnet-xxxxxxxx", "subnet-yyyyyyyy"]
  
  instance_type = "t3.micro"
  ami_id        = "ami-xxxxxxxxx"
  
  asg_desired_capacity = 2
  asg_min_size         = 2
  asg_max_size         = 4
}
```

## Inputs

See `variables.tf` for all available inputs.

## Outputs

See `outputs.tf` for all available outputs.