# Auto Scaling Group Terraform Infrastructure

Multi-environment Terraform infrastructure for managing Auto Scaling Groups across DEV, QA, and PROD environments using a single configuration with environment-specific tfvars files.

## Directory Structure
```
terraform/
├── modules/
│   └── autoscaling/          # Reusable ASG module
│       ├── main.tf
│       ├── variables.tf
│       ├── outputs.tf
│       └── README.md
├── main.tf                   # Main Terraform configuration
├── variables.tf              # Variable definitions
├── outputs.tf                # Output definitions
├── backend.tf                # Backend configuration
├── terraform.dev.tfvars      # DEV environment variables
├── terraform.qa.tfvars       # QA environment variables
├── terraform.prod.tfvars     # PROD environment variables
├── .gitignore
└── README.md
```

## Prerequisites

1. **Terraform**: Version >= 1.0
2. **AWS CLI**: Configured with appropriate credentials
3. **AWS Account**: With necessary permissions
4. **S3 Buckets**: For Terraform state (one per environment)
5. **DynamoDB Tables**: For state locking (one per environment)

## Initial Setup

### 1. Create S3 Buckets and DynamoDB Tables

Run these AWS CLI commands to create backend resources for each environment:
```bash
# Function to create backend resources
create_backend() {
  ENV=$1
  
  # Create S3 bucket
  aws s3 mb s3://mcharles-terraform-state-${ENV} --region us-east-1
  
  # Enable versioning
  aws s3api put-bucket-versioning \
    --bucket mcharles-terraform-state-${ENV} \
    --versioning-configuration Status=Enabled
  
  # Enable encryption
  aws s3api put-bucket-encryption \
    --bucket mcharles-terraform-state-${ENV} \
    --server-side-encryption-configuration '{
      "Rules": [{
        "ApplyServerSideEncryptionByDefault": {
          "SSEAlgorithm": "AES256"
        }
      }]
    }'
  
  # Block public access
  aws s3api put-public-access-block \
    --bucket mcharles-terraform-state-${ENV} \
    --public-access-block-configuration \
    "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true"
  
  # Create DynamoDB table
  aws dynamodb create-table \
    --table-name terraform-state-lock-${ENV} \
    --attribute-definitions AttributeName=LockID,AttributeType=S \
    --key-schema AttributeName=LockID,KeyType=HASH \
    --billing-mode PAY_PER_REQUEST \
    --region us-east-1 \
    --tags Key=Environment,Value=${ENV} Key=ManagedBy,Value=Terraform
}

# Create backend for each environment
create_backend dev
create_backend qa
create_backend prod
```

### 2. Update tfvars Files

Update each `terraform.{environment}.tfvars` file with your specific values:
- VPC IDs
- Subnet IDs
- AMI IDs
- Key pair names
- CIDR blocks

## Local Usage

### Deploy to DEV
```bash
cd terraform

# Initialize with DEV backend
terraform init \
  -backend-config="bucket=mcharles-terraform-state-dev" \
  -backend-config="key=autoscaling/dev/terraform.tfstate" \
  -backend-config="region=us-east-1" \
  -backend-config="encrypt=true" \
  -backend-config="dynamodb_table=terraform-state-lock-dev"

# Plan with DEV variables
terraform plan -var-file="terraform.dev.tfvars"

# Apply with DEV variables
terraform apply -var-file="terraform.dev.tfvars"

# View outputs
terraform output
```

### Deploy to QA
```bash
cd terraform

# Initialize with QA backend
terraform init -reconfigure \
  -backend-config="bucket=mcharles-terraform-state-qa" \
  -backend-config="key=autoscaling/qa/terraform.tfstate" \
  -backend-config="region=us-east-1" \
  -backend-config="encrypt=true" \
  -backend-config="dynamodb_table=terraform-state-lock-qa"

# Plan and apply
terraform plan -var-file="terraform.qa.tfvars"
terraform apply -var-file="terraform.qa.tfvars"
```

### Deploy to PROD
```bash
cd terraform

# Initialize with PROD backend
terraform init -reconfigure \
  -backend-config="bucket=mcharles-terraform-state-prod" \
  -backend-config="key=autoscaling/prod/terraform.tfstate" \
  -backend-config="region=us-east-1" \
  -backend-config="encrypt=true" \
  -backend-config="dynamodb_table=terraform-state-lock-prod"

# Plan and apply
terraform plan -var-file="terraform.prod.tfvars"
terraform apply -var-file="terraform.prod.tfvars"
```

## GitHub Actions Deployment

### Manual Deployment via Workflow Dispatch

1. Go to **Actions** tab in GitHub
2. Select **Terraform Infrastructure Deployment** workflow
3. Click **Run workflow**
4. Select:
   - **Environment**: dev, qa, or prod
   - **Action**: plan, apply, or destroy
5. Click **Run workflow**

### Automatic Deployments

- **Pull Requests**: Automatically runs `terraform plan` for DEV environment
- **Push to main**: Automatically runs `terraform apply` for DEV environment

### Environment Secrets

Configure the following secrets in GitHub for each environment:

**Settings → Environments → [dev/qa/prod] → Secrets**

- `AWS_ACCESS_KEY_ID`
- `AWS_SECRET_ACCESS_KEY`

## Deployment Workflow

### Standard Promotion Process

1. **Development**
```bash
   # Local testing
   terraform plan -var-file="terraform.dev.tfvars"
   terraform apply -var-file="terraform.dev.tfvars"
```
   
   Or via GitHub Actions:
   - Create PR → Auto plan runs
   - Merge to main → Auto apply to DEV

2. **QA**
   - Use GitHub Actions workflow dispatch
   - Select `qa` environment and `apply` action
   - Review and approve

3. **Production**
   - Use GitHub Actions workflow dispatch
   - Select `prod` environment and `apply` action
   - Require approval from team lead
   - Monitor deployment

## Helper Scripts

### `scripts/deploy.sh`

Create a helper script for local deployments:
```bash
#!/bin/bash

# Usage: ./scripts/deploy.sh <environment> <action>
# Example: ./scripts/deploy.sh dev plan

set -e

ENVIRONMENT=$1
ACTION=$2

if [ -z "$ENVIRONMENT" ] || [ -z "$ACTION" ]; then
  echo "Usage: $0 <environment> <action>"
  echo "  environment: dev, qa, prod"
  echo "  action: init, plan, apply, destroy"
  exit 1
fi

if [[ ! "$ENVIRONMENT" =~ ^(dev|qa|prod)$ ]]; then
  echo "Error: Environment must be dev, qa, or prod"
  exit 1
fi

if [[ ! "$ACTION" =~ ^(init|plan|apply|destroy|output)$ ]]; then
  echo "Error: Action must be init, plan, apply, destroy, or output"
  exit 1
fi

cd terraform

echo "=========================================="
echo "Environment: $ENVIRONMENT"
echo "Action: $ACTION"
echo "=========================================="

if [ "$ACTION" == "init" ]; then
  terraform init -reconfigure \
    -backend-config="bucket=mcharles-terraform-state-${ENVIRONMENT}" \
    -backend-config="key=autoscaling/${ENVIRONMENT}/terraform.tfstate" \
    -backend-config="region=us-east-1" \
    -backend-config="encrypt=true" \
    -backend-config="dynamodb_table=terraform-state-lock-${ENVIRONMENT}"
elif [ "$ACTION" == "plan" ]; then
  terraform plan -var-file="terraform.${ENVIRONMENT}.tfvars"
elif [ "$ACTION" == "apply" ]; then
  terraform apply -var-file="terraform.${ENVIRONMENT}.tfvars"
elif [ "$ACTION" == "destroy" ]; then
  terraform destroy -var-file="terraform.${ENVIRONMENT}.tfvars"
elif [ "$ACTION" == "output" ]; then
  terraform output
fi

echo "=========================================="
echo "Completed: $ACTION for $ENVIRONMENT"
echo "=========================================="
```

Make it executable:
```bash
chmod +x scripts/deploy.sh
```

Usage:
```bash
./scripts/deploy.sh dev init
./scripts/deploy.sh dev plan
./scripts/deploy.sh dev apply
./scripts/deploy.sh qa plan
./scripts/deploy.sh prod apply
```

## Useful Commands
```bash
# Format all Terraform files
terraform fmt -recursive

# Validate configuration
terraform validate

# Show current state
terraform show

# List all resources
terraform state list

# Get specific output
terraform output autoscaling_group_name

# Refresh state
terraform refresh -var-file="terraform.dev.tfvars"

# Import existing resource
terraform import -var-file="terraform.dev.tfvars" \
  module.autoscaling.aws_autoscaling_group.asg \
  myapp-dev-asg-xxxxxxxx
```

## Monitoring and Troubleshooting

### CloudWatch Logs

View logs in CloudWatch:
- `/aws/ec2/myapp-dev`
- `/aws/ec2/myapp-qa`
- `/aws/ec2/myapp-prod`

### CloudWatch Alarms

Monitor alarms for:
- High CPU utilization
- Unhealthy instances

### AWS CLI Commands
```bash
# View ASG details
aws autoscaling describe-auto-scaling-groups \
  --auto-scaling-group-names myapp-dev-asg-xxxxx

# View ASG instances
aws autoscaling describe-auto-scaling-instances

# View launch template versions
aws ec2 describe-launch-template-versions \
  --launch-template-id lt-xxxxx

# View CloudWatch metrics
aws cloudwatch get-metric-statistics \
  --namespace AWS/EC2 \
  --metric-name CPUUtilization \
  --dimensions Name=AutoScalingGroupName,Value=myapp-dev-asg-xxxxx \
  --start-time 2025-02-01T00:00:00Z \
  --end-time 2025-02-05T00:00:00Z \
  --period 3600 \
  --statistics Average
```

## Troubleshooting

### State Lock Issues
```bash
# View lock info
aws dynamodb get-item \
  --table-name terraform-state-lock-dev \
  --key '{"LockID":{"S":"mcharles-terraform-state-dev/autoscaling/dev/terraform.tfstate-md5"}}'

# Force unlock (use with caution!)
terraform force-unlock <LOCK_ID>
```

### Backend Migration
```bash
# Migrate from one backend to another
terraform init -migrate-state \
  -backend-config="bucket=new-bucket" \
  -backend-config="key=new-key"
```

### Common Errors

1. **Backend initialization error**
```bash
   terraform init -reconfigure
```

2. **State file locked**
```bash
   # Wait for lock to release or force unlock
   terraform force-unlock <LOCK_ID>
```

3. **Resource already exists**
```bash
   # Import the resource
   terraform import module.autoscaling.aws_autoscaling_group.asg <asg-name>
```

## Security Best Practices

1. **Never commit sensitive data** to Git
2. **Use environment-specific AWS credentials**
3. **Enable MFA** for production deployments
4. **Restrict S3 bucket access** to authorized users only
5. **Enable CloudTrail** for audit logging
6. **Review security group rules** regularly
7. **Use least privilege IAM policies**

## CI/CD Best Practices

1. **Always run `plan` before `apply`**
2. **Require approvals for production deployments**
3. **Use branch protection rules**
4. **Run security scans** (tfsec, checkov)
5. **Test in DEV/QA before PROD**
6. **Keep tfvars files in sync** with actual infrastructure

## Support and Documentation

- **Module Documentation**: See `modules/autoscaling/README.md`
- **Terraform Docs**: https://www.terraform.io/docs
- **AWS Provider Docs**: https://registry.terraform.io/providers/hashicorp/aws/latest/docs

## License

Internal use only - [Your Company Name]