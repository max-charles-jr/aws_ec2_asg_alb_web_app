# Backend configuration for remote state storage
# The backend is configured dynamically via backend-config during terraform init
# Example: terraform init -backend-config="key=autoscaling/${var.environment}/terraform.tfstate"

terraform {
  backend "s3" {
    # These values will be provided via backend-config or environment variables
    # bucket         = "mcharles-terraform-state"
    # key            = "autoscaling/${var.environment}/terraform.tfstate"
    # region         = "us-east-1"
    # encrypt        = true
    # dynamodb_table = "terraform-state-lock"
  }
}
