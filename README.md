# 🎉 Guest List Infrastructure Deployment

A comprehensive **DevSecOps** project that deploys a Guest List API to Amazon EKS using Infrastructure as Code (Terraform) with proper security, scalability, cost optimization, and **multi-student deployment support**.

## 🏗️ Architecture Overview

This project demonstrates modern DevSecOps practices by deploying:

- **Application**: Flask-based REST API ([Guest-List-API](https://github.com/giligalili/Guest-List-API))
- **Infrastructure**: AWS EKS cluster with VPC, security groups, and load balancers
- **Orchestration**: Kubernetes deployments with auto-scaling and health checks
- **Security**: Network security groups, IAM policies, and container security
- **Monitoring**: Health checks, resource limits, and logging
- **Multi-Student Support**: Individual deployments with unique cluster names and resource tagging

### Infrastructure Components

| Component | Description | Cost (Monthly) |
|-----------|-------------|----------------|
| **EKS Cluster** | Managed Kubernetes control plane (v1.28) | ~$72.00 |
| **EC2 Nodes** | Worker nodes (2x t3.small instances) | ~$30.40 |
| **VPC & Networking** | Custom VPC with public/private subnets across 2 AZs | ~$32.40 |
| **Load Balancer** | Network Load Balancer for external access | ~$16.20 |
| **Total Estimate** | | **~$151/month** |

## 📁 Project Structure

```
Guest-List-Deploy/
├── 📄 README.md                    # This comprehensive guide
├── 📄 WINDOWS-SETUP.md            # Windows-specific setup guide
├── 📄 DEPLOYMENT-CHECKLIST.md     # Step-by-step verification checklist
├── 📄 MIGRATION-GUIDE.md          # Documentation of changes made
├── 🚀 deploy.ps1                   # Enhanced PowerShell deployment script
├── 🚀 deploy.bat                   # Enhanced batch deployment script
├── 📁 environments/                # Environment-specific configurations
│   ├── 📁 dev/
│   │   └── terraform.tfvars        # Development environment settings
│   ├── 📁 staging/
│   │   └── terraform.tfvars        # Staging environment settings
│   └── 📁 prod/
│       └── terraform.tfvars        # Production environment settings
├── 📁 terraform/                   # Infrastructure as Code
│   ├── 📁 modules/                 # Reusable Terraform modules
│   │   ├── 📁 vpc/                 # VPC and networking resources
│   │   │   ├── main.tf, variables.tf, outputs.tf
│   │   ├── 📁 eks/                 # EKS cluster and node groups  
│   │   │   ├── main.tf, variables.tf, outputs.tf
│   │   └── 📁 security/            # Security groups and policies
│   │       ├── main.tf, variables.tf, outputs.tf
│   ├── main.tf                     # Main Terraform configuration
│   ├── variables.tf                # Input variables
│   ├── outputs.tf                  # Output values
│   └── versions.tf                 # Version constraints
└── 📁 k8s-manifests/              # Kubernetes resource definitions
    ├── 📁 namespaces/, deployments/, services/, configmaps/, ingress/
```

## 🚀 Quick Start for Students

### Student Names: `sivan`, `dvir`, `saar`, `gili`

Each student can deploy their own isolated infrastructure with unique cluster names and resource tagging.

### Prerequisites

Before you begin, ensure you have:

#### Required Tools
- **AWS CLI** configured with appropriate permissions
- **Terraform** (v1.0+)
- **kubectl** for Kubernetes management
- **PowerShell** (Windows) or **bash** (Linux/macOS)

#### Required AWS IAM Permissions
- `AmazonEKSClusterPolicy`
- `AmazonEKSWorkerNodePolicy`
- `AmazonEKS_CNI_Policy`
- `AmazonEC2ContainerRegistryReadOnly`
- VPC and EC2 management permissions

For Windows-specific setup, see [WINDOWS-SETUP.md](WINDOWS-SETUP.md).

### 🎯 Student Deployment Options

#### **Option 1: Super Simple Deployment (Recommended)**
```powershell
# Clone the repository
git clone https://github.com/giligalili/Guest-List-Deploy.git
cd Guest-List-Deploy

# Deploy with your username (automatically creates unique configuration)
.\deploy.ps1 -UserName "sivan" -Environment dev

# This automatically creates:
# - Cluster: guestlist-sivan-dev
# - Student name: sivan
# - All resources tagged with your name
```

#### **Option 2: Manual Configuration**
```powershell
# Clone and navigate
git clone https://github.com/giligalili/Guest-List-Deploy.git
cd Guest-List-Deploy

# Copy and customize environment file
cp environments\dev\terraform.tfvars environments\dev\terraform.tfvars.local

# Edit with your details:
# cluster_name = "guestlist-sivan-dev"  # Make unique!
# student_name = "sivan"                # Your name
notepad environments\dev\terraform.tfvars.local

# Deploy
.\deploy.ps1 -Environment dev
```

### 🎓 Student-Specific Examples

```powershell
# Sivan's deployment
.\deploy.ps1 -UserName "sivan" -Environment dev

# Dvir's deployment  
.\deploy.ps1 -UserName "dvir" -Environment dev

# Saar's deployment
.\deploy.ps1 -UserName "saar" -Environment dev

# Gili's deployment
.\deploy.ps1 -UserName "gili" -Environment dev

# Each creates a unique cluster:
# - guestlist-sivan-dev
# - guestlist-dvir-dev
# - guestlist-saar-dev  
# - guestlist-gili-dev
```

## 💰 Cost Management & Transparency

### 📊 Cost Display Before Deployment

The script now shows detailed cost estimates before any deployment:

```
ESTIMATED MONTHLY COSTS:
  EKS Cluster:              ~$72.00
  EC2 Nodes (2x t3.small): ~$30.40
  NAT Gateway:              ~$32.40
  Load Balancer:            ~$16.20
  -------------------------
  TOTAL ESTIMATED:          ~$151.00/month

IMPORTANT: You will be charged by AWS for these resources!
Do you want to proceed with deployment? Type 'yes' to continue
```

### 💡 Cost Optimization Options

#### **Ultra-Cheap Configuration** (~$120/month)
```hcl
# In your terraform.tfvars.local file:
node_instance_type     = "t3.micro"     # Smallest instance
node_desired_capacity  = 1              # Single node
app_replicas          = 1               # Single app instance
```

#### **Spot Instances** (~60-70% savings)
```hcl
# Add to your configuration:
capacity_type = "SPOT"                  # Use Spot instances
```

#### **Minimal Development** (~$135/month)
```hcl
# Balanced cost vs. functionality:
node_instance_type     = "t3.small"     # Good performance
node_desired_capacity  = 1              # Single node for dev
node_max_capacity      = 2              # Limited scaling
```

## 🎯 Deployment Commands

### **PowerShell Commands (Windows)**

```powershell
# Quick deployment with cost approval
.\deploy.ps1 -UserName "sivan" -Environment dev

# Plan only (see costs and resources, no deployment)
.\deploy.ps1 -UserName "sivan" -Environment dev -Plan

# Auto-approve (skip manual confirmation)
.\deploy.ps1 -UserName "sivan" -Environment dev -AutoApprove

# Deploy to staging
.\deploy.ps1 -UserName "sivan" -Environment staging

# Destroy infrastructure (STOP ALL CHARGES)
.\deploy.ps1 -UserName "sivan" -Environment dev -Destroy
```

### **Batch Commands (Windows)**

```cmd
REM Deploy for specific user
deploy.bat dev sivan

REM Deploy to staging for user
deploy.bat staging dvir

REM Still works without username
deploy.bat dev
```

### **Manual Terraform (Advanced)**

```bash
cd terraform
terraform init
terraform plan -var-file="../environments/dev/terraform.tfvars.local"
terraform apply -var-file="../environments/dev/terraform.tfvars.local"
```

## 🧪 Testing Your Deployment

### After Deployment Completes

1. **Get Your Application URL**:
```bash
# From terraform output
terraform output application_url

# Or from kubectl
kubectl get service guestlist-service -n guestlist-dev
```

2. **Test API Endpoints**:
```bash
# Replace with your actual load balancer URL
LB_URL="your-load-balancer-url"

# Get all guests
curl http://$LB_URL/guests

# Health check
curl http://$LB_URL/health

# Add a new guest
curl -X POST http://$LB_URL/guests \
  -H "Content-Type: application/json" \
  -d '{
    "firstname": "John",
    "surname": "Doe", 
    "quantity": "2",
    "phone": "0541234567",
    "email": "john@example.com",
    "guest_id": "JD2025"
  }'
```

## 📊 Monitoring and Management

### View Your Resources
```bash
# Check cluster status
kubectl get nodes

# Check your application
kubectl get pods -n guestlist-dev
kubectl get services -n guestlist-dev

# View application logs
kubectl logs -l app=guestlist -n guestlist-dev

# Check auto-scaling
kubectl describe hpa guestlist-hpa -n guestlist-dev
```

### Scaling Operations
```bash
# Scale application manually
kubectl scale deployment guestlist-deployment --replicas=5 -n guestlist-dev

# Scale infrastructure (edit your .tfvars.local file)
# Update node_desired_capacity, then:
terraform apply -var-file="../environments/dev/terraform.tfvars.local"
```

### AWS Console Access
- **EKS Console**: Monitor your cluster
- **Cost Explorer**: Track your AWS spending
- **CloudWatch**: View logs and metrics
- **EC2 Console**: Monitor your instances

## 🛡️ Security Features

### Infrastructure Security
- **Private subnets** for worker nodes
- **Security groups** with restricted access
- **IAM policies** with least privilege
- **Network ACLs** for additional protection

### Application Security
- **Container security context** (non-root user)
- **Resource limits** to prevent resource exhaustion
- **Health checks** for reliability
- **ConfigMaps** for secure configuration management

### Student Isolation
- **Unique cluster names** per student
- **Separate resource tagging** for cost tracking
- **Individual namespaces** for application isolation
- **Independent AWS resource groups**

## 🔧 Advanced Configuration

### Environment-Specific Deployments

```powershell
# Development (cheapest)
.\deploy.ps1 -UserName "sivan" -Environment dev      # t3.small, 2 nodes

# Staging (moderate)
.\deploy.ps1 -UserName "sivan" -Environment staging  # t3.medium, 2 nodes

# Production (performance)
.\deploy.ps1 -UserName "sivan" -Environment prod     # t3.large, 3 nodes
```

### Custom Resource Sizing

Edit your `environments/{env}/terraform.tfvars.local`:

```hcl
# Custom configuration example
cluster_name           = "guestlist-sivan-dev"
student_name          = "sivan"
aws_region            = "us-west-2"
environment           = "dev"

# Performance settings
node_instance_type     = "t3.medium"        # More CPU/memory
node_desired_capacity  = 3                  # More nodes
node_max_capacity      = 5                  # Higher scaling limit

# Application settings  
app_replicas          = 3                   # More app instances

# Cost vs. performance tags
common_tags = {
  Environment = "dev"
  Project     = "guest-list"
  Owner       = "sivan"
  Performance = "optimized"              # Track configuration type
  Course      = "DevSecOps"
}
```

## 🆘 Troubleshooting

### Common Issues

**Terraform initialization fails:**
- Check if you have duplicate `providers.tf` and `main.tf` configurations
- Solution: `del terraform\providers.tf` (main.tf has the providers)

**kubectl connection issues:**
- Ensure AWS CLI region matches terraform region
- Run: `aws eks update-kubeconfig --region us-west-2 --name guestlist-[yourname]-dev`

**Pods not starting:**
- Check node capacity: `kubectl describe nodes`
- View pod logs: `kubectl logs -n guestlist-dev [pod-name]`

**Cost concerns:**
- Monitor AWS billing dashboard daily
- Set up AWS billing alerts
- Use `terraform destroy` when not actively developing
- Consider Spot instances for development

**Cluster name conflicts:**
- Always use unique cluster names (automatic with -UserName parameter)
- Check existing clusters: `aws eks list-clusters`

## 🧹 Cleanup (STOP ALL CHARGES!)

**⚠️ CRITICAL: Always clean up resources to avoid charges!**

### Quick Cleanup
```powershell
# Destroy all resources for your deployment
.\deploy.ps1 -UserName "sivan" -Environment dev -Destroy

# Confirm by typing 'yes' when prompted
```

### Manual Cleanup
```bash
cd terraform
terraform destroy -var-file="../environments/dev/terraform.tfvars.local"
# Type 'yes' when prompted
```

### Verify Cleanup
- Check AWS EKS Console (no clusters should remain)
- Check EC2 Console (no instances should remain)
- Check VPC Console (VPCs should be deleted)
- Monitor AWS billing for next few days

## 🎓 Learning Outcomes

This project demonstrates:

### DevSecOps Practices
- **Infrastructure as Code** (Terraform modules)
- **Container Orchestration** (Kubernetes)
- **Cloud Security** (AWS IAM, VPC, Security Groups)
- **Cost Optimization** (Instance sizing, resource management)
- **Monitoring & Observability** (Health checks, logging)
- **Multi-tenant Architecture** (Student isolation)

### Technical Skills
- **Terraform Modules** for reusable infrastructure
- **Kubernetes Deployments** with auto-scaling
- **AWS EKS** managed Kubernetes service
- **Network Security** with proper segmentation
- **Automated Deployments** with user management
- **Cost Management** and optimization strategies

## 👥 Multi-Student Deployment Summary

### Student Configurations

| Student | Cluster Name | Namespace | Tags |
|---------|--------------|-----------|------|
| sivan | guestlist-sivan-dev | guestlist-dev | Owner: sivan |
| dvir | guestlist-dvir-dev | guestlist-dev | Owner: dvir |
| saar | guestlist-saar-dev | guestlist-dev | Owner: saar |
| gili | guestlist-gili-dev | guestlist-dev | Owner: gili |

### Resource Isolation
- **Separate EKS clusters** per student
- **Individual cost tracking** via AWS tags
- **Unique load balancer URLs** per deployment
- **Independent scaling** and configuration

### Deployment Commands Quick Reference
```powershell
# Each student uses their name
.\deploy.ps1 -UserName "sivan" -Environment dev    # Sivan's deployment
.\deploy.ps1 -UserName "dvir" -Environment dev     # Dvir's deployment  
.\deploy.ps1 -UserName "saar" -Environment dev     # Saar's deployment
.\deploy.ps1 -UserName "gili" -Environment dev     # Gili's deployment

# Cleanup (each student)
.\deploy.ps1 -UserName "sivan" -Environment dev -Destroy
.\deploy.ps1 -UserName "dvir" -Environment dev -Destroy
.\deploy.ps1 -UserName "saar" -Environment dev -Destroy
.\deploy.ps1 -UserName "gili" -Environment dev -Destroy
```

## 🤝 Contributing

This is an educational project for DevSecOps learning. Students can:
- Report issues or bugs
- Suggest cost optimization improvements
- Submit pull requests for enhancements
- Share deployment experiences and lessons learned

## 📚 Additional Resources

- [AWS EKS Best Practices](https://aws.github.io/aws-eks-best-practices/)
- [Terraform AWS Provider Documentation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [Guest List API Repository](https://github.com/giligalili/Guest-List-API)
- [AWS Cost Management](https://aws.amazon.com/aws-cost-management/)

## 📋 Quick Reference

### Essential Commands
```powershell
# Deploy
.\deploy.ps1 -UserName "[your-name]" -Environment dev

# Check costs first
.\deploy.ps1 -UserName "[your-name]" -Environment dev -Plan

# Destroy (STOP CHARGES)
.\deploy.ps1 -UserName "[your-name]" -Environment dev -Destroy

# Check your resources
kubectl get all -n guestlist-dev
terraform output
```

### Cost Estimates
- **Minimal**: ~$120/month (t3.micro, 1 node)
- **Standard**: ~$151/month (t3.small, 2 nodes) 
- **Optimized**: ~$181/month (t3.medium, 2 nodes)
- **Spot Instances**: 30-40% savings on EC2 costs

---

**📞 Support**: If you encounter issues, check the troubleshooting section or create an issue in this repository.

**💡 Pro Tips**: 
- Always use unique cluster names (automatic with `-UserName`)
- Monitor AWS costs daily during active development
- Destroy resources immediately when done testing
- Use `-Plan` flag to see costs before deploying
- Set up AWS billing alerts for cost control

**⚠️ Remember**: This is a learning environment - always clean up resources to avoid unexpected charges!

---

Made with ❤️ for DevSecOps learning  
**Students**: Sivan, Dvir, Saar, and Gili
