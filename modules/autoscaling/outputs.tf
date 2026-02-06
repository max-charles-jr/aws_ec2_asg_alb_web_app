output "autoscaling_group_id" {
  description = "The Auto Scaling Group ID"
  value       = aws_autoscaling_group.asg.id
}

output "autoscaling_group_name" {
  description = "The Auto Scaling Group name"
  value       = aws_autoscaling_group.asg.name
}

output "autoscaling_group_arn" {
  description = "The ARN of the Auto Scaling Group"
  value       = aws_autoscaling_group.asg.arn
}

output "launch_template_id" {
  description = "The ID of the launch template"
  value       = aws_launch_template.asg_lt.id
}

output "launch_template_latest_version" {
  description = "The latest version of the launch template"
  value       = aws_launch_template.asg_lt.latest_version
}

output "security_group_id" {
  description = "The ID of the security group"
  value       = aws_security_group.asg_sg.id
}

output "security_group_name" {
  description = "The name of the security group"
  value       = aws_security_group.asg_sg.name
}

output "iam_role_arn" {
  description = "The ARN of the IAM role"
  value       = aws_iam_role.ec2_role.arn
}

output "iam_role_name" {
  description = "The name of the IAM role"
  value       = aws_iam_role.ec2_role.name
}

output "iam_instance_profile_arn" {
  description = "The ARN of the IAM instance profile"
  value       = aws_iam_instance_profile.ec2_profile.arn
}

output "cloudwatch_log_group_name" {
  description = "The name of the CloudWatch log group"
  value       = aws_cloudwatch_log_group.asg_logs.name
}

output "cloudwatch_log_group_arn" {
  description = "The ARN of the CloudWatch log group"
  value       = aws_cloudwatch_log_group.asg_logs.arn
}
