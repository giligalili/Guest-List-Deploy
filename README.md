# 🚀 Guest List Deploy

Infrastructure as Code (IaC) deployment for the Guest List API using Terraform and AWS EKS. This repository contains all the necessary configurations to deploy our Flask application to a production-ready Kubernetes cluster on AWS.

**Team:** Gili, Sivan, Sahar & Dvir  
**Course:** DevSecOps Final Project

---

## 🏗️ Infrastructure Overview

### Architecture Components

- **AWS EKS**: Managed Kubernetes cluster with auto-scaling
- **DynamoDB**: Serverless NoSQL database for guest data
- **VPC**: Custom networking with public/private subnets
- **Load Balancer**: External access with health checks
- **IAM**: Secure role-based access control
- **Terraform**: Infrastructure as Code with remote state management

### Environment Strategy

Our deployment supports multiple environments with isolated resources:

- **Student Environments**: `gili`, `sivan`, `sahar`, `dvir` - Individual development
- **Shared Environments**: `dev`, `staging`, `main` - Team collaboration
- **Feature Branches**: Automatic deployment for student feature work

---

## 🚀 Quick Start

### Prerequisites

1. **AWS CLI** configured with appropriate credentials
2. **Terraform** (>= 1.0.0, < 1.10.0)
3. **kubectl** for cluster management
4. **Docker Hub** access for container images

### Initial Setup

```bash
# Clone the repository
git clone https://github.com/giligalili/Guest-List-Deploy.git
cd Guest-List-Deploy

# Configure your environment
export AWS_REGION=us-east-1
export ENVIRONMENT=gili  # or sivan, sahar, dvir, dev, staging, main
```

### State Backend Setup (First Time Only)

```bash
# Create Terraform backend resources
terraform init
terraform apply -var="create_state_backend=true" \
  -var="state_bucket_name=guestlist-tfstate-${ENVIRONMENT}"
```

### Deploy Infrastructure

```bash
# Initialize with remote state
terraform init -reconfigure \
  -backend-config="bucket=guestlist-tfstate-${ENVIRONMENT}" \
  -backend-config="key=envs/${ENVIRONMENT}/terraform.tfstate" \
  -backend-config="region=${AWS_REGION}"

# Plan deployment
terraform plan -var="environment=${ENVIRONMENT}" \
  -var="aws_access_key_id=${AWS_ACCESS_KEY_ID}" \
  -var="aws_secret_access_key=${AWS_SECRET_ACCESS_KEY}"

# Apply changes
terraform apply -auto-approve
```

---

## 📁 Repository Structure

```
.
├── backend.tf                    # Terraform remote state configuration
├── main.tf                      # VPC, networking, and core infrastructure
├── eks.tf                       # EKS cluster and node group definitions
├── dynamodb.tf                  # DynamoDB table configuration
├── kubernetes.tf                # Kubernetes deployments and services
├── iam.tf                       # IAM roles and policies (commented)
├── variables.tf                 # Input variables and configuration
├── outputs.tf                   # Output values and connection info
├── provider.tf                  # AWS provider configuration
├── state-bucket.tf              # S3 backend bucket creation
├── clean-terraform.yml          # GitHub Actions CI/CD pipeline
├── guestlistapi-LB-service.yaml # Kubernetes LoadBalancer service
└── .gitignore                   # Comprehensive gitignore for security
```

---

## 🔧 Infrastructure Components

### VPC and Networking (`main.tf`)

**Custom VPC Setup:**
- CIDR: 10.0.0.0/16 (65,536 IP addresses)
- **Public Subnets**: 10.0.1.0/24, 10.0.2.0/24 (for load balancers)
- **Private Subnets**: 10.0.10.0/24, 10.0.11.0/24 (for worker nodes)
- **NAT Gateway**: Single gateway for cost optimization
- **Internet Gateway**: Public internet access

**High Availability:**
- Multi-AZ deployment across 2 availability zones
- Separate route tables for public and private subnets
- Security groups with minimal required access

### EKS Cluster (`eks.tf`)

**Cluster Configuration:**
- Kubernetes version: 1.28
- **Control Plane**: Fully managed by AWS
- **Node Group**: t3.small instances (cost-optimized)
- **Scaling**: 1-3 nodes with desired capacity of 2
- **Logging**: API and audit logs enabled

**IAM Integration:**
- Option to use existing IAM roles or create new ones
- Support for both managed and pre-existing role scenarios
- Proper policy attachments for EKS functionality

### DynamoDB (`dynamodb.tf`)

**Database Setup:**
- **Table Name**: `GuestList-{environment}`
- **Primary Key**: `id` (String)
- **Billing**: Pay-per-request (serverless)
- **Tags**: Environment and student identification

### Kubernetes Deployments (`kubernetes.tf`)

**Application Deployment:**
- **Namespace**: `guestlist` for all environments
- **Replicas**: 3 for high availability
- **Resource Limits**: CPU and memory constraints
- **Health Checks**: Readiness and liveness probes
- **Environment Variables**: AWS credentials via Kubernetes secrets

**Load Balancer Service:**
- **Type**: LoadBalancer (AWS ELB integration)
- **Port Mapping**: External 9999 → Internal 1111
- **Health Checks**: Automatic endpoint monitoring

---

## 🌍 Environment Management

### State Management Strategy

Each environment maintains isolated Terraform state:

```
S3 Structure:
├── guestlist-tfstate-gili/envs/gili/terraform.tfstate
├── guestlist-tfstate-sivan/envs/sivan/terraform.tfstate  
├── guestlist-tfstate-sahar/envs/sahar/terraform.tfstate
├── guestlist-tfstate-dvir/envs/dvir/terraform.tfstate
├── guestlist-tfstate-dev/envs/dev/terraform.tfstate
├── guestlist-tfstate-staging/envs/staging/terraform.tfstate
└── guestlist-tfstate-main/envs/main/terraform.tfstate
```

### Resource Naming Convention

Resources are tagged and named consistently:
- **Pattern**: `{resource-type}-{environment}`
- **Example**: `GuestList-gili`, `guestlist-cluster-sivan`
- **Tags**: Environment, Student, Project identification

### Variable Configuration

**Core Variables** (defined in `variables.tf`):
```hcl
variable "environment" {
  description = "Environment name (gili, sivan, sahar, dvir, dev, staging, main)"
  type        = string
}

variable "aws_region" {
  description = "AWS region for deployment"  
  type        = string
  default     = "us-east-1"
}

variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
  default     = "guestlist-cluster"
}
```

---

## 🤖 CI/CD Pipeline - Complete Workflow Analysis

### Advanced GitHub Actions Pipeline (`clean-terraform.yml`)

Our deployment pipeline is a sophisticated multi-stage process that handles environment resolution, infrastructure provisioning, and health validation.

#### **Workflow Triggers & Input Management**
```yaml
on:
  push:
    branches: [ main ]           # Automatic production deployment
  workflow_dispatch:             # Manual deployment with options
    inputs:
      action:
        type: choice
        options: [plan, apply, destroy]
      environment: 
        type: choice
        options: [sivan, dvir, gili, sahar, dev, staging, main]
```

**Trigger Strategy:**
- **Automatic**: Push to `main` → Production deployment
- **Manual**: Developers can deploy to any environment with specific actions
- **Safety**: Manual destroy prevents accidental resource deletion

---

### 🎯 Stage 1: Environment Determination (`determine-environment`)

**Dynamic Environment Resolution:**
```bash
# Automatic environment detection
if [[ "${GITHUB_EVENT_NAME}" == "push" && "${GITHUB_REF_NAME}" == "main" ]]; then
  ENVIRONMENT="main"
else
  # Manual selection with fallback
  ENVIRONMENT="${{ github.event.inputs.environment || 'dev' }}"
fi
```

**Resource Naming Strategy:**
```bash
# State bucket naming for isolation
case "${ENVIRONMENT}" in
  sivan|dvir|sahar|gili)
    TF_STATE_BUCKET="guestlist-tfstate-${ENVIRONMENT}-feature"
    ;;
  *)
    TF_STATE_BUCKET="guestlist-tfstate-${ENVIRONMENT}"
    ;;
esac

# State key path: envs/{environment}/terraform.tfstate
TF_STATE_KEY="envs/${ENVIRONMENT}/terraform.tfstate"
```

**Docker Image Tag Resolution:**
```bash
IMAGE_REPO="giligalili/guestlistapi"
case "${ENVIRONMENT}" in
  sivan|dvir|sahar|gili)
    IMAGE_TAG_PREFIX="${ENVIRONMENT}-feature-"  # Dynamic latest feature
    ;;
  dev|staging|main)
    IMAGE_TAG_PREFIX="${ENVIRONMENT}"           # Fixed environment tags
    ;;
esac
```

**Output Variables:**
- `environment`: Target deployment environment
- `namespace`: Kubernetes namespace (`guestlist`)  
- `tf_state_bucket`: Environment-specific S3 bucket
- `tf_state_key`: State file path within bucket
- `image_repo`: Docker registry repository
- `image_tag_prefix`: Tag pattern for image resolution

---

### 🏗️ Stage 2: Infrastructure Configuration (`configure-environment`)

**AWS Credentials Setup:**
```yaml
- name: Configure AWS credentials
  uses: aws-actions/configure-aws-credentials@v4
  with:
    aws-region: ${{ env.AWS_REGION }}
    aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
    aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
```

**Idempotent S3 Backend Creation:**
```bash
# Create S3 bucket with proper configuration
if aws s3api head-bucket --bucket "$B" 2>/dev/null; then
  echo "Bucket $B exists."
else
  # Regional bucket creation
  if [[ "$R" == "us-east-1" ]]; then
    aws s3api create-bucket --bucket "$B"
  else
    aws s3api create-bucket --bucket "$B" \
      --create-bucket-configuration LocationConstraint="$R"
  fi
  
  # Security hardening
  aws s3api put-bucket-versioning --bucket "$B" \
    --versioning-configuration Status=Enabled
  aws s3api put-bucket-encryption --bucket "$B" \
    --server-side-encryption-configuration '{
      "Rules":[{"ApplyServerSideEncryptionByDefault":{"SSEAlgorithm":"AES256"}}]}'
  aws s3api put-public-access-block --bucket "$B" \
    --public-access-block-configuration \
    BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true
fi
```

**DynamoDB Lock Table Creation:**
```bash
# Terraform state locking
aws dynamodb create-table \
  --table-name "terraform-locks" \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST
aws dynamodb wait table-exists --table-name "terraform-locks"
```

**Security Features:**
- **Encryption**: S3 buckets encrypted at rest with AES256
- **Versioning**: State file history for rollback capability
- **Public Access Block**: Prevents accidental public exposure
- **State Locking**: DynamoDB prevents concurrent modifications

---

### 🚀 Stage 3: Terraform Deployment (`terraform`)

**Environment Setup & Variables:**
```bash
# Environment-specific configuration
ENVIRONMENT: ${{ needs.determine-environment.outputs.environment }}
TF_STATE_BUCKET: ${{ needs.determine-environment.outputs.tf_state_bucket }}
TF_VAR_cluster_role_name: guestlist-cluster-cluster-role
TF_VAR_node_group_role_name: guestlist-cluster-node-group-role
```

**Dynamic Docker Image Resolution:**
```bash
# Resolve latest feature image for students
case "${ENVIRONMENT}" in
  sivan|dvir|sahar|gili)
    # Query Docker Hub API for latest feature tag
    tag="$(curl -fsSL "https://hub.docker.com/v2/repositories/${repo}/tags?page_size=100" \
      | jq -r '.results[] | select(.name | startswith("'"${prefix}"'")) | .name' | head -n1)"
    ;;
  dev|staging|main)
    tag="${prefix}"  # Use fixed environment tag
    ;;
esac
```

**Docker Hub API Integration:**
- **Live Tag Resolution**: Queries Docker Hub for latest feature builds
- **Fallback Strategy**: Default tags for stable environments
- **Error Handling**: Pipeline fails if image tag cannot be resolved

**Terraform Initialization:**
```bash
terraform init -input=false -reconfigure \
  -backend-config="bucket=${TF_STATE_BUCKET}" \
  -backend-config="key=${TF_STATE_KEY}" \
  -backend-config="region=${AWS_REGION}" \
  -backend-config="dynamodb_table=terraform-locks"
```

**Plan Generation:**
```bash
terraform plan -input=false \
  -var="environment=${ENVIRONMENT}" \
  -var="aws_region=${AWS_REGION}" \
  -var="namespace=${NAMESPACE}" \
  -var="image_tag=${{ steps.imagetag.outputs.image_tag }}" \
  -var="aws_access_key_id=${{ secrets.AWS_ACCESS_KEY_ID }}" \
  -var="aws_secret_access_key=${{ secrets.AWS_SECRET_ACCESS_KEY }}" \
  -out=tfplan-${ENVIRONMENT}
```

**Conditional Execution Logic:**
```yaml
# Plan: Manual 'plan' action OR push to main
- name: Terraform Plan
  if: |
    (github.event_name == 'workflow_dispatch' && inputs.action == 'plan') ||
    (github.event_name == 'push' && github.ref == 'refs/heads/main')

# Apply: Manual 'apply' action OR push to main  
- name: Terraform Apply
  if: |
    (github.event_name == 'workflow_dispatch' && inputs.action == 'apply') ||
    (github.event_name == 'push' && github.ref == 'refs/heads/main')

# Destroy: Manual 'destroy' action ONLY
- name: Terraform Destroy
  if: ${{ github.event_name == 'workflow_dispatch' && inputs.action == 'destroy' }}
```

---

### 🏥 Stage 4: Health Validation & Monitoring

**LoadBalancer Endpoint Discovery:**
```bash
# Try to read IP first; fallback to hostname
LB="$(terraform output -raw load_balancer_ip 2>/dev/null || true)"
USE_DNS=0
if [[ -z "${LB}" ]]; then
  LB="$(terraform output -raw load_balancer_hostname 2>/dev/null || true)"
  USE_DNS=1
fi
```

**DNS Resolution Waiting:**
```bash
# Wait for DNS propagation (AWS ELB hostnames)
if [[ "${USE_DNS}" -eq 1 ]]; then
  echo "Waiting for DNS to resolve for ${LB}..."
  for i in {1..120}; do
    if getent hosts "${LB}" >/dev/null 2>&1; then
      echo "DNS resolved on attempt #${i}"
      break
    fi
    sleep 5
    [[ $i -eq 120 ]] && { echo "Timed out waiting for DNS"; exit 1; }
  done
fi
```

**Comprehensive Health Checking:**
```bash
# Multi-endpoint health validation
BASE_URL="http://${LB}:9999"
ATTEMPTS=30
SLEEP=10

for i in $(seq 1 $ATTEMPTS); do
  # Primary health check
  CODE="$(curl -sS -m 5 -o /dev/null -w '%{http_code}' "${BASE_URL}/healthz" || echo "000")"
  if [[ "$CODE" -ge 200 && "$CODE" -lt 400 ]]; then
    echo "OK: HTTP $CODE from ${BASE_URL}/healthz"
    exit 0
  fi
  
  # Fallback root check
  CODE_ROOT="$(curl -sS -m 5 -o /dev/null -w '%{http_code}' "${BASE_URL}/" || echo "000")"
  if [[ "$CODE_ROOT" -ge 200 && "$CODE_ROOT" -lt 400 ]]; then
    echo "OK: HTTP $CODE_ROOT from ${BASE_URL}/"
    exit 0
  fi
  
  echo "Attempt $i/$ATTEMPTS: healthz=$CODE root=$CODE_ROOT — retrying in ${SLEEP}s..."
  sleep $SLEEP
done
```

**Health Check Features:**
- **Dual Endpoint Testing**: `/healthz` (Kubernetes probe) + `/` (application)
- **Timeout Handling**: 5-second curl timeout per attempt
- **Progressive Retry**: 30 attempts with 10-second intervals (5-minute total)
- **DNS Awareness**: Waits for AWS ELB hostname resolution
- **Detailed Logging**: Reports HTTP codes and attempt progress

---

### 🔄 Advanced Workflow Features

**Multi-Environment GitHub Environments:**
```yaml
environment: ${{ needs.determine-environment.outputs.environment }}
```
- **Environment Protection**: GitHub environment-specific secrets
- **Approval Gates**: Manual approval for sensitive environments
- **Variable Scoping**: Environment-specific configuration

**Terraform Variable Injection:**
```bash
# Comprehensive variable passing
terraform apply -input=false -auto-approve \
  -var="environment=${ENVIRONMENT}" \
  -var="aws_region=${AWS_REGION}" \
  -var="namespace=${NAMESPACE}" \
  -var="image_tag=${{ steps.imagetag.outputs.image_tag }}" \
  -var="aws_access_key_id=${{ secrets.AWS_ACCESS_KEY_ID }}" \
  -var="aws_secret_access_key=${{ secrets.AWS_SECRET_ACCESS_KEY }}"
```

**Plan Reuse Logic:**
```bash
# Use generated plan if available, otherwise apply directly
if [[ -f "tfplan-${ENVIRONMENT}" ]]; then
  terraform apply -input=false -auto-approve "tfplan-${ENVIRONMENT}"
else
  terraform apply -input=false -auto-approve [variables...]
fi
```

---

### 🎯 Workflow Execution Patterns

**Production Deployment (Automatic):**
```
git push origin main
└── determine-environment (ENVIRONMENT=main)
    └── configure-environment (production secrets)
        └── terraform (plan + apply)
            └── health-validation (production LB)
```

**Development Deployment (Manual):**
```
Workflow Dispatch: environment=gili, action=apply
└── determine-environment (ENVIRONMENT=gili)
    └── configure-environment (gili-feature bucket)
        └── terraform (apply with gili-feature-{sha} image)
            └── health-validation (development LB)
```

**Infrastructure Planning (Manual):**
```
Workflow Dispatch: environment=staging, action=plan
└── determine-environment (ENVIRONMENT=staging)
    └── configure-environment (staging bucket)
        └── terraform (plan only, no apply)
```

**Resource Cleanup (Manual):**
```
Workflow Dispatch: environment=dev, action=destroy
└── determine-environment (ENVIRONMENT=dev)
    └── configure-environment (dev bucket)
        └── terraform (destroy with confirmation)
```

### 🔒 Security & Best Practices

**Secrets Management:**
- GitHub repository secrets for AWS credentials
- Environment-specific secret scoping
- No hardcoded credentials in workflow files

**State Security:**
- S3 bucket encryption and versioning
- DynamoDB locking prevents race conditions
- Private bucket configuration blocks public access

**Failure Handling:**
- Explicit error codes and logging
- Container cleanup on test failure
- Terraform state protection with locks

**Resource Isolation:**
- Environment-specific S3 buckets and DynamoDB tables
- Kubernetes namespace separation
- Unique resource tagging for identification

---

## 🔐 Security Configuration

### IAM Role Management

**Flexible IAM Strategy:**
- **Option 1**: Pre-existing roles (default, `manage_iam = false`)
- **Option 2**: Terraform-managed roles (`manage_iam = true`)

**Required Roles:**
```hcl
variable "cluster_role_name" {
  default = "guestlist-cluster-cluster-role"
}

variable "node_group_role_name" {  
  default = "guestlist-cluster-node-group-role"
}
```

### Secrets Management

**Kubernetes Secrets:**
- AWS credentials stored as Kubernetes secrets
- Environment variables injected into containers
- No hardcoded credentials in code

**GitHub Secrets Required:**
- `AWS_ACCESS_KEY_ID`: AWS programmatic access
- `AWS_SECRET_ACCESS_KEY`: AWS secret key

### Network Security

**Security Groups:**
- Cluster security group: Minimal required access
- Node security group: Inter-node and cluster communication
- No unnecessary port exposure

**VPC Configuration:**
- Private subnets for worker nodes
- Public subnets only for load balancers
- NAT gateway for outbound internet access

---

## 📊 Cost Optimization

### Resource Sizing

**EKS Cluster:**
- t3.small instances (2 vCPU, 2GB RAM)
- Minimum node count: 1
- Maximum node count: 3 (auto-scaling)

**Cost Estimates** (Monthly, US East 1):
```
EKS Control Plane:     ~$72.00  (24/7 management)
t3.small Nodes (2x):   ~$30.40  (2 × $15.20/month)  
NAT Gateway:           ~$32.40  (gateway + data transfer)
Load Balancer:         ~$16.20  (Classic Load Balancer)
DynamoDB:              ~$0.00   (free tier eligible)
Total Estimate:        ~$151.00/month
```

### Cost Optimization Features

- **Single NAT Gateway**: Shared across availability zones
- **Pay-per-request DynamoDB**: No provisioned capacity
- **Minimal node group**: Small instance types
- **Horizontal Pod Autoscaler**: Scale based on CPU usage
- **Resource limits**: Prevent resource waste

---

## 📈 Monitoring and Observability

### Health Checks

**Application Level:**
- `/health`: Application health with guest count
- `/healthz`: Basic liveness probe
- `/readyz`: Readiness probe with dependency checks

**Kubernetes Level:**
- Readiness probes: Initial 10s delay, 5s intervals
- Liveness probes: 20s delay, 10s intervals
- Failure thresholds: 3-6 attempts before restart

### Outputs and Monitoring

**Terraform Outputs:**
```hcl
output "load_balancer_ip" {
  description = "LoadBalancer external access point"
  value       = kubernetes_service.guestlist_service.status[0].load_balancer[0].ingress[0].hostname
}

output "kubectl_config" {
  description = "Command to configure kubectl access"  
  value       = "aws eks update-kubeconfig --region ${var.aws_region} --name ${var.cluster_name}"
}
```

### EKS Cluster Logging

**Enabled Log Types:**
- **API Server**: All API requests and responses
- **Audit**: Security-relevant chronological records
- **CloudWatch Integration**: Centralized log management

---

## 🛠️ Troubleshooting Guide

### Common Issues

**Terraform State Lock:**
```bash
# If state is locked, check DynamoDB
aws dynamodb scan --table-name terraform-locks

# Force unlock if needed (use carefully)
terraform force-unlock <lock-id>
```

**EKS Cluster Access:**
```bash
# Update kubectl configuration
aws eks update-kubeconfig --region us-east-1 --name guestlist-cluster

# Verify cluster access
kubectl get nodes
kubectl get pods -n guestlist
```

**LoadBalancer Not Accessible:**
```bash
# Check service status
kubectl get svc -n guestlist

# Check pod status  
kubectl get pods -n guestlist
kubectl describe pod -n guestlist <pod-name>

# Check logs
kubectl logs -n guestlist <pod-name>
```

**Docker Image Pull Issues:**
```bash
# Verify image exists
docker pull giligalili/guestlistapi:latest

# Check deployment image reference
kubectl describe deployment -n guestlist guestlist-deployment
```

### Pipeline Debugging

**Failed Terraform Apply:**
1. Check AWS credentials are valid
2. Verify S3 state bucket exists and is accessible  
3. Ensure DynamoDB lock table exists
4. Check IAM permissions for EKS operations

**Health Check Failures:**
1. Verify LoadBalancer DNS resolution
2. Check security group configurations
3. Confirm application is running in pods
4. Validate DynamoDB table access

---

## 🚀 Advanced Usage

### Multiple Environment Management

**Deploy Multiple Environments:**
```bash
# Deploy development environment
terraform workspace select dev || terraform workspace new dev
terraform apply -var="environment=dev"

# Deploy staging environment  
terraform workspace select staging || terraform workspace new staging
terraform apply -var="environment=staging"
```

### Custom Configuration

**Override Default Settings:**
```bash
# Custom instance types
terraform apply -var="node_instance_type=t3.medium" \
  -var="node_desired_capacity=3"

# Custom region deployment
terraform apply -var="aws_region=us-west-2" \
  -var="environment=west-coast"
```

### Blue-Green Deployment

**Rolling Updates:**
- Kubernetes deployment strategy: RollingUpdate
- Max surge: 25% additional pods during update
- Max unavailable: 0% (zero downtime updates)

---

## 🤝 Team Contributions

**Infrastructure Development:**
- **Gili**: EKS cluster configuration, Kubernetes manifests, security groups
- **Sivan**: VPC networking, subnet design, NAT gateway optimization
- **Sahar**: CI/CD pipeline, GitHub Actions, environment management strategy  
- **Dvir**: DynamoDB configuration, IAM roles, cost optimization analysis

**Collaboration:**
- All team members contributed to code review and testing
- Shared responsibility for documentation and troubleshooting guides
- Cross-training on AWS services and Terraform best practices

---

## 🔄 Deployment Workflow

### Development Workflow

1. **Feature Development**: Work in `{name}-feature` branches
2. **Local Testing**: Test application changes locally
3. **CI Pipeline**: Automated Docker build and testing  
4. **Infrastructure Deploy**: Manual trigger or push to main
5. **Validation**: Health checks and smoke testing
6. **Production**: Merge to main for production deployment

### Environment Promotion

```bash
# Development → Staging
git checkout staging
git merge dev
git push origin staging

# Staging → Production  
git checkout main
git merge staging
git push origin main
```

---

## 📚 Additional Resources

### Useful Commands

**Cluster Management:**
```bash
# Get cluster information
kubectl cluster-info
kubectl get nodes -o wide

# Application management
kubectl get all -n guestlist
kubectl logs -f deployment/guestlist-deployment -n guestlist

# Resource monitoring
kubectl top nodes
kubectl top pods -n guestlist
```

**Terraform Operations:**
```bash
# View current state
terraform show
terraform state list

# Import existing resources (if needed)
terraform import aws_s3_bucket.tf_state bucket-name

# Clean up
terraform destroy -auto-approve
```

### Related Documentation

- [Guest List API Repository](https://github.com/giligalili/Guest-List-API)
- [AWS EKS Documentation](https://docs.aws.amazon.com/eks/)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [Kubernetes Documentation](https://kubernetes.io/docs/)

---

## 📄 License

This infrastructure code was created as part of our DevSecOps course final project. All team members contributed to the design and implementation.

---

**Ready to deploy your Guest List API to the cloud? Follow this guide and you'll have a production-ready Kubernetes cluster running on AWS in minutes! 🚀**
