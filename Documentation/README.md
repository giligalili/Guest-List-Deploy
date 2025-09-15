# 🎉 Guest List Infrastructure Deployment

A comprehensive **DevSecOps** project that deploys a Guest List API to Amazon EKS using Infrastructure as Code (Terraform) with proper security, scalability, and cost optimization.

## 🏗️ Architecture Overview

This project demonstrates modern DevSecOps practices by deploying:

- **Application**: Flask-based REST API ([Guest-List-API](https://github.com/giligalili/Guest-List-API))
- **Infrastructure**: AWS EKS cluster with VPC, security groups, and load balancers
- **Orchestration**: Kubernetes deployments with auto-scaling and health checks
- **Security**: Network security groups, IAM policies, and container security
- **Monitoring**: Health checks, resource limits, and logging

### Infrastructure Components

| Component | Description | Cost (Monthly) |
|-----------|-------------|----------------|
| **EKS Cluster** | Managed Kubernetes control plane (v1.28) | ~$72.00 |
| **EC2 Nodes** | Worker nodes (t3.small instances) | ~$30.40 (2 nodes) |
| **VPC & Networking** | Custom VPC with public/private subnets across 2 AZs | ~$32.40 |
| **Load Balancer** | Network Load Balancer for external access | ~$16.20 |
| **Total Estimate** | | **~$151/month** |

## 📁 Project Structure

```
Guest-List-Deploy/
├── 📄 README.md                    # This file
├── 📄 WINDOWS-SETUP.md            # Windows-specific setup guide
├── 🚀 deploy.ps1                   # PowerShell deployment script
├── 🚀 deploy.bat                   # Batch deployment script
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
│   │   ├── 📁 eks/                 # EKS cluster and node groups
│   │   └── 📁 security/            # Security groups and policies
│   ├── main.tf                     # Main Terraform configuration
│   ├── variables.tf                # Input variables
│   ├── outputs.tf                  # Output values
│   ├── providers.tf                # Provider configurations
│   └── versions.tf                 # Version constraints
└── 📁 k8s-manifests/              # Kubernetes resource definitions
    ├── 📁 namespaces/              # Namespace definitions
    ├── 📁 deployments/             # Application deployments
    ├── 📁 services/                # Service definitions
    ├── 📁 configmaps/              # Configuration maps
    └── 📁 ingress/                 # Ingress controllers
```

## 🚀 Quick Start

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

### 🎯 Deployment Steps

#### 1. Clone and Setup
```bash
git clone https://github.com/giligalili/Guest-List-Deploy.git
cd Guest-List-Deploy
```

#### 2. Configure Environment
```bash
# Copy environment template (choose your environment)
cp environments/dev/terraform.tfvars environments/dev/terraform.tfvars.local

# Edit the local configuration
nano environments/dev/terraform.tfvars.local
```

**Key configurations to customize:**
```hcl
cluster_name         = "guestlist-[your-name]"    # Make unique!
student_name        = "your-actual-name"          # Your name
aws_region          = "us-west-2"                 # Your preferred region
environment         = "dev"

# Cost optimization
node_instance_type     = "t3.small"               # or t3.micro for cheaper
node_desired_capacity  = 2                        # or 1 for minimal cost
```

#### 3. Deploy Infrastructure

**Option A: PowerShell (Recommended)**
```powershell
# Deploy to development
.\deploy.ps1

# Deploy to specific environment
.\deploy.ps1 -Environment staging

# Plan only (no deployment)
.\deploy.ps1 -Plan

# Destroy infrastructure
.\deploy.ps1 -Destroy
```

**Option B: Command Prompt**
```cmd
REM Deploy to development
deploy.bat

REM Deploy to specific environment
deploy.bat staging
```

**Option C: Manual Terraform**
```bash
cd terraform
terraform init
terraform plan -var-file="../environments/dev/terraform.tfvars.local"
terraform apply -var-file="../environments/dev/terraform.tfvars.local"
```

#### 4. Configure kubectl
After deployment completes:
```bash
# The output will show the command, but it's typically:
aws eks update-kubeconfig --region us-west-2 --name guestlist-[your-name]

# Verify connection
kubectl get nodes
kubectl get pods -n guestlist-dev
```

## 🧪 Testing Your Deployment

### Get Load Balancer URL
```bash
# From Terraform output
terraform output application_url

# Or directly from Kubernetes
kubectl get service guestlist-service -n guestlist-dev
```

### API Testing Commands
```bash
# Get the load balancer hostname
LB_HOST=$(terraform output -raw load_balancer_ip)

# Test endpoints
curl http://$LB_HOST/guests                    # Get all guests
curl http://$LB_HOST/health                    # Health check

# Add a new guest
curl -X POST http://$LB_HOST/guests \
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

### View Resources
```bash
# Check cluster status
kubectl get nodes
kubectl get pods -n guestlist-dev
kubectl get services -n guestlist-dev

# View application logs
kubectl logs -l app=guestlist -n guestlist-dev

# Check horizontal pod autoscaler
kubectl describe hpa guestlist-hpa -n guestlist-dev
```

### Scaling Operations
```bash
# Scale application manually
kubectl scale deployment guestlist-deployment --replicas=5 -n guestlist-dev

# Scale node group (via Terraform)
# Update node_desired_capacity in terraform.tfvars.local
terraform apply -var-file="../environments/dev/terraform.tfvars.local"
```

### AWS Console Access
- **EKS Console**: `https://us-west-2.console.aws.amazon.com/eks/home?region=us-west-2#/clusters/guestlist-[your-name]`
- **Cost Explorer**: Monitor your AWS spending
- **CloudWatch**: View logs and metrics

## 💰 Cost Management

### Cost Optimization Tips
- **Use t3.micro instances** (cheaper but less performant):
  ```hcl
  node_instance_type = "t3.micro"
  ```
- **Minimal deployment** for testing:
  ```hcl
  node_desired_capacity = 1
  app_replicas = 1
  ```
- **Use Spot instances** for development:
  ```hcl
  capacity_type = "SPOT"
  ```
- **Deploy in us-east-1** for lowest pricing

### Estimated Costs by Configuration

| Configuration | Monthly Cost |
|--------------|--------------|
| **Minimal** (1x t3.micro) | ~$120 |
| **Development** (2x t3.small) | ~$151 |
| **Staging** (2x t3.medium) | ~$181 |
| **Production** (3x t3.large) | ~$245 |

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

### DevSecOps Best Practices
- **Infrastructure as Code** for consistency
- **Environment separation** (dev/staging/prod)
- **Automated deployments** with validation
- **Cost monitoring** and alerting

## 🔧 Advanced Configuration

### Environment-Specific Deployments
```bash
# Deploy to different environments
.\deploy.ps1 -Environment dev      # Development
.\deploy.ps1 -Environment staging  # Staging  
.\deploy.ps1 -Environment prod     # Production
```

### Custom Configurations
Each environment supports:
- Different instance types and capacities
- Custom application replicas
- Environment-specific tags
- Region-specific deployments

### Enable Features
- **Cluster autoscaling**: Install cluster autoscaler addon
- **Monitoring**: Deploy Prometheus/Grafana stack
- **SSL/TLS**: Configure ALB with SSL certificates
- **CI/CD**: Integrate with GitHub Actions or Jenkins

## 🆘 Troubleshooting

### Common Issues

**Terraform timeout:**
- EKS cluster creation takes 15-20 minutes
- Monitor progress in AWS Console

**kubectl connection issues:**
- Ensure AWS CLI is configured: `aws sts get-caller-identity`
- Run kubectl config command from terraform output

**Pods not starting:**
- Check node capacity: `kubectl describe nodes`
- View pod logs: `kubectl logs -n guestlist-dev [pod-name]`

**Cost concerns:**
- Monitor AWS billing dashboard
- Use `terraform destroy` when not needed
- Consider Spot instances for development

### Getting Help
- Check AWS EKS troubleshooting guide
- Review Terraform AWS provider documentation
- Monitor CloudWatch logs for detailed error messages

## 🧹 Cleanup

**IMPORTANT**: Always clean up resources to avoid charges!

```bash
# Destroy all resources
.\deploy.ps1 -Destroy

# Or manually
cd terraform
terraform destroy -var-file="../environments/dev/terraform.tfvars.local"
```

Type `yes` when prompted to confirm destruction.

## 🎓 Learning Outcomes

This project demonstrates:

### DevSecOps Practices
- **Infrastructure as Code** (Terraform)
- **Container Orchestration** (Kubernetes)
- **Cloud Security** (AWS IAM, VPC, Security Groups)
- **Cost Optimization** (Instance sizing, resource management)
- **Monitoring & Observability** (Health checks, logging)

### Technical Skills
- **Terraform Modules** for reusable infrastructure
- **Kubernetes Deployments** with auto-scaling
- **AWS EKS** managed Kubernetes service
- **Network Security** with proper segmentation
- **Automated Deployments** with validation scripts

## 🤝 Contributing

This is a educational project for DevSecOps learning. Feel free to:
- Report issues or bugs
- Suggest improvements
- Submit pull requests
- Share your deployment experiences

## 📚 Additional Resources

- [AWS EKS Best Practices](https://aws.github.io/aws-eks-best-practices/)
- [Terraform AWS Provider Documentation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [Guest List API Repository](https://github.com/giligalili/Guest-List-API)

## 📝 License

This project is for educational purposes as part of a DevSecOps course.

---

**📞 Support**: If you encounter issues, please check the troubleshooting section or create an issue in this repository.

**💡 Tips**: 
- Always use unique cluster names to avoid conflicts
- Monitor AWS costs regularly
- Remember to destroy resources when done testing
- This configuration is optimized for learning, not production use

---

Made with ❤️ for DevSecOps learning
