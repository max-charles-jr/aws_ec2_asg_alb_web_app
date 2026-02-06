output "environment" {
  description = "The deployed environment"
  value       = var.environment
}

output "autoscaling_group_id" {
  description = "The Auto Scaling Group ID"
  value       = module.autoscaling.autoscaling_group_id
}

output "autoscaling_group_name" {
  description = "The Auto Scaling Group name"
  value       = module.autoscaling.autoscaling_group_name
}

output "autoscaling_group_arn" {
  description = "The ARN of the Auto Scaling Group"
  value       = module.autoscaling.autoscaling_group_arn
}

output "launch_template_id" {
  description = "The ID of the launch template"
  value       = module.autoscaling.launch_template_id
}

output "launch_template_latest_version" {
  description = "The latest version of the launch template"
  value       = module.autoscaling.launch_template_latest_version
}

output "security_group_id" {
  description = "The ID of the security group"
  value       = module.autoscaling.security_group_id
}

output "security_group_name" {
  description = "The name of the security group"
  value       = module.autoscaling.security_group_name
}

output "iam_role_arn" {
  description = "The ARN of the IAM role"
  value       = module.autoscaling.iam_role_arn
}

output "iam_role_name" {
  description = "The name of the IAM role"
  value       = module.autoscaling.iam_role_name
}

output "iam_instance_profile_arn" {
  description = "The ARN of the IAM instance profile"
  value       = module.autoscaling.iam_instance_profile_arn
}

output "cloudwatch_log_group_name" {
  description = "The name of the CloudWatch log group"
  value       = module.autoscaling.cloudwatch_log_group_name
}

output "cloudwatch_log_group_arn" {
  description = "The ARN of the CloudWatch log group"
  value       = module.autoscaling.cloudwatch_log_group_arn
}
