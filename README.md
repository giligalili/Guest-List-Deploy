# Guest List API - AWS EKS Deployment Guide

This Terraform configuration deploys your Guest List API to Amazon EKS with cost optimization and environment variable support.

## 🏗️ Architecture Overview

- **VPC**: Custom VPC with public/private subnets across 2 AZs
- **EKS Cluster**: Managed Kubernetes cluster (v1.28)
- **Node Group**: 1-3 t3.small instances (cost-optimized)
- **Load Balancer**: AWS Load Balancer for external access
- **Networking**: Single NAT Gateway for cost savings

## 💰 Estimated Costs (Monthly)

- EKS Cluster: ~$72.00
- EC2 Nodes (2x t3.small): ~$30.40
- NAT Gateway: ~$32.40
- Load Balancer: ~$16.20
- **Total: ~$151/month**

**Cost Reduction Tips:**
- Use `t3.micro` instances (cheaper but less performant)
- Set `node_desired_capacity = 1` for minimal deployment
- Use Spot instances (change `capacity_type = "SPOT"` in eks.tf)
- Deploy in `us-east-1` for lowest pricing

## 🚀 Prerequisites

1. **AWS CLI** configured with appropriate permissions:
   ```bash
   aws configure
   ```

2. **Terraform** installed (v1.0+):
   ```bash
   # MacOS
   brew install terraform
   
   # Ubuntu/Debian
   wget https://releases.hashicorp.com/terraform/1.6.0/terraform_1.6.0_linux_amd64.zip
   unzip terraform_1.6.0_linux_amd64.zip
   sudo mv terraform /usr/local/bin/
   ```

3. **kubectl** installed:
   ```bash
   # MacOS
   brew install kubectl
   
   # Ubuntu/Debian
   curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
   sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
   ```

4. **Required AWS IAM Permissions:**
   - AmazonEKSClusterPolicy
   - AmazonEKSWorkerNodePolicy
   - AmazonEKS_CNI_Policy
   - AmazonEC2ContainerRegistryReadOnly
   - VPC and EC2 management permissions

## 🔧 Environment Setup

### 🪟 Windows Users
See **[WINDOWS-SETUP.md](WINDOWS-SETUP.md)** for Windows-specific instructions and PowerShell/Batch scripts.

**Quick Windows Start:**
```powershell
# PowerShell (Recommended)
.\deploy.ps1

# Command Prompt
deploy.bat
```

### 🐧 Linux/Mac Users

### Step 1: Customize Variables

1. Copy the `terraform.tfvars` file:
   ```bash
   cp terraform.tfvars terraform.tfvars.local
   ```

2. Edit `terraform.tfvars.local` with your specific values:
   ```hcl
   # CUSTOMIZE THESE VALUES
   cluster_name = "guestlist-[your-name]"  # Make unique!
   student_name = "your-actual-name"
   aws_region   = "us-west-2"              # Your preferred region
   environment  = "dev"
   
   # Cost optimization
   node_instance_type    = "t3.small"     # or t3.micro for cheaper
   node_desired_capacity = 2              # or 1 for minimal cost
   ```

### Step 2: Deploy Infrastructure

1. **Initialize Terraform:**
   ```bash
   terraform init
   ```

2. **Plan the deployment:**
   ```bash
   terraform plan -var-file="terraform.tfvars.local"
   ```

3. **Apply the configuration:**
   ```bash
   terraform apply -var-file="terraform.tfvars.local"
   ```
   Type `yes` when prompted.

4. **Wait for completion** (15-20 minutes for EKS cluster creation)

### Step 3: Configure kubectl

After deployment completes, configure kubectl:
```bash
# Get the kubectl config command from terraform output
terraform output kubectl_config

# Run the command (example)
aws eks update-kubeconfig --region us-west-2 --name guestlist-cluster
```

### Step 4: Verify Deployment

1. **Check cluster status:**
   ```bash
   kubectl get nodes
   kubectl get pods -n guestlist-dev
   ```

2. **Get Load Balancer URL:**
   ```bash
   kubectl get service guestlist-service -n guestlist-dev
   ```

3. **Test the API:**
   ```bash
   # Get the load balancer hostname
   LB_HOST=$(terraform output -raw load_balancer_ip)
   
   # Test the API
   curl http://$LB_HOST/guests
   ```

## 🧪 Testing Your API

Once deployed, you can test your Guest List API:

```bash
# Get all guests
curl http://[LOAD_BALANCER_URL]/guests

# Add a new guest
curl -X POST http://[LOAD_BALANCER_URL]/guests \
  -H "Content-Type: application/json" \
  -d '{
    "firstname": "John",
    "surname": "Doe", 
    "quantity": "2",
    "phone": "0541234567",
    "email": "john@example.com",
    "id": "JD2025"
  }'
```

## 📊 Monitoring and Management

1. **View cluster in AWS Console:**
   - Go to EKS service in AWS Console
   - Select your cluster to view details

2. **Monitor costs:**
   - Use AWS Cost Explorer
   - Set up billing alerts

3. **Scale the application:**
   ```bash
   # Scale deployment
   kubectl scale deployment guestlist-deployment --replicas=5 -n guestlist-dev
   
   # Scale node group (via Terraform)
   # Update node_desired_capacity in terraform.tfvars.local
   terraform apply -var-file="terraform.tfvars.local"
   ```

## 🧹 Cleanup

**IMPORTANT:** Always clean up resources to avoid charges!

```bash
# Destroy all resources
terraform destroy -var-file="terraform.tfvars.local"
```

Type `yes` when prompted. This will delete all AWS resources created by Terraform.

## 🔒 Security Notes

- EKS cluster has both private and public API endpoints
- Worker nodes are in private subnets
- Security groups restrict access appropriately
- Consider enabling cluster logging for production use

## 🐛 Troubleshooting

**Common Issues:**

1. **Terraform timeout:**
   - EKS cluster creation can take 15-20 minutes
   - Wait and check AWS Console for progress

2. **kubectl connection issues:**
   - Ensure AWS CLI is configured correctly
   - Run the kubectl update-kubeconfig command from output

3. **Pods not starting:**
   - Check node capacity: `kubectl describe nodes`
   - Check pod logs: `kubectl logs -n guestlist-dev [pod-name]`

4. **Cost concerns:**
   - Monitor AWS billing dashboard
   - Use `terraform destroy` when not needed
   - Consider using Spot instances for development

## 📝 Notes for Students

- Each student should use a unique `cluster_name` to avoid conflicts
- Customize the `student_name` variable for resource tagging
- Monitor your AWS costs regularly
- Remember to destroy resources when done testing
- This configuration is optimized for learning, not production

## 🔧 Advanced Customization

To further customize your deployment:

1. **Use Spot instances** (cheaper but can be terminated):
   - Edit `eks.tf`, change `capacity_type = "SPOT"`

2. **Add additional environments:**
   - Create separate `.tfvars` files for dev/staging/prod
   - Deploy multiple environments with different names

3. **Enable cluster autoscaling:**
   - Install cluster autoscaler addon
   - Adjust node group scaling parameters

4. **Add monitoring:**
   - Deploy Prometheus/Grafana for monitoring
   - Enable CloudWatch logging
