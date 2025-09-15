# 📋 Deployment Checklist - Multi-Student Edition

Use this checklist to ensure successful deployment of your Guest List infrastructure with **multi-student support**.

**Students**: `sivan`, `dvir`, `saar`, `gili` - each gets isolated infrastructure.

## ✅ Pre-Deployment Checklist

### Prerequisites Verification
- [ ] AWS CLI installed and configured (`aws --version`)
- [ ] Terraform installed (v1.0+) (`terraform --version`)
- [ ] kubectl installed (`kubectl version --client`)
- [ ] AWS credentials configured (`aws sts get-caller-identity`)
- [ ] Git installed and repository cloned
- [ ] PowerShell execution policy set (Windows)

### AWS Permissions Verification
- [ ] `AmazonEKSClusterPolicy`
- [ ] `AmazonEKSWorkerNodePolicy` 
- [ ] `AmazonEKS_CNI_Policy`
- [ ] `AmazonEC2ContainerRegistryReadOnly`
- [ ] VPC and EC2 management permissions
- [ ] Load Balancer permissions
- [ ] IAM role creation permissions

### Student Configuration
- [ ] Student name confirmed: `sivan` | `dvir` | `saar` | `gili`
- [ ] Unique cluster name will be auto-generated: `guestlist-[name]-dev`
- [ ] Environment selected: `dev` | `staging` | `prod`
- [ ] Cost profile understood and accepted

## 🚀 Deployment Process Options

### Option 1: Super Simple Deployment (Recommended)

**Using UserName Parameter:**
- [ ] Navigate to project root directory
- [ ] Run: `.\deploy.ps1 -UserName "[your-name]" -Environment dev`
- [ ] Script automatically creates unique configuration
- [ ] Review cost estimates displayed (~$151/month)
- [ ] Type 'yes' to approve deployment when prompted

### Option 2: Manual Configuration

**Traditional approach:**
- [ ] Copy environment file: `environments/dev/terraform.tfvars` to `environments/dev/terraform.tfvars.local`
- [ ] Edit local file with unique settings:
  - [ ] `cluster_name = "guestlist-[your-name]-dev"`
  - [ ] `student_name = "[your-name]"`
  - [ ] `common_tags.Owner = "[your-name]"`
- [ ] Run: `.\deploy.ps1 -Environment dev`

### Option 3: Batch Script (Windows)
- [ ] Run: `deploy.bat dev [your-name]`
- [ ] Follow prompts for cost approval

## 🧪 Student-Specific Deployment Tests

### Per-Student Verification

**For Sivan:**
- [ ] Cluster name: `guestlist-sivan-dev`
- [ ] All resources tagged with `Owner: sivan`
- [ ] Unique load balancer URL

**For Dvir:**
- [ ] Cluster name: `guestlist-dvir-dev`
- [ ] All resources tagged with `Owner: dvir`
- [ ] Unique load balancer URL

**For Saar:**
- [ ] Cluster name: `guestlist-saar-dev`
- [ ] All resources tagged with `Owner: saar`
- [ ] Unique load balancer URL

**For Gili:**
- [ ] Cluster name: `guestlist-gili-dev`
- [ ] All resources tagged with `Owner: gili`
- [ ] Unique load balancer URL

## 💰 Cost Management Checklist

### Pre-Deployment Cost Review
- [ ] Cost estimates displayed before deployment
- [ ] Monthly estimate: ~$151 for standard config
- [ ] Alternative cost options reviewed:
  - [ ] Ultra-cheap (~$120): `t3.micro`, 1 node
  - [ ] Spot instances (~30-40% savings)
  - [ ] Minimal config: 1 node, 1 replica

### Cost Approval Process
- [ ] Cost breakdown understood:
  - [ ] EKS Cluster: ~$72.00/month
  - [ ] EC2 Nodes: ~$30.40/month (2x t3.small)
  - [ ] NAT Gateway: ~$32.40/month
  - [ ] Load Balancer: ~$16.20/month
- [ ] Manual approval given (typed 'yes')
- [ ] AWS billing dashboard setup for monitoring

## 🔧 Deployment Process Verification

### Terraform Initialization
- [ ] `terraform init` completed successfully
- [ ] No duplicate provider configuration errors
- [ ] All modules downloaded and initialized

### Planning Phase
- [ ] `terraform plan` executed without errors
- [ ] Resource count matches expectations (~40-50 resources)
- [ ] Student-specific naming visible in plan output
- [ ] No resource conflicts with other students

### Apply Phase
- [ ] Final cost confirmation displayed
- [ ] Manual approval given for resource creation
- [ ] `terraform apply` completed successfully (15-20 minutes)
- [ ] All resources created with proper tags
- [ ] No timeout or error messages

### Kubernetes Configuration
- [ ] kubectl configured automatically
- [ ] `kubectl get nodes` shows worker nodes (usually 2)
- [ ] `kubectl get pods -n guestlist-dev` shows running pods
- [ ] Application pods in "Running" status
- [ ] Load balancer service has external IP assigned

## 🧪 Post-Deployment Testing

### Infrastructure Verification
- [ ] EKS cluster active in AWS Console
- [ ] EC2 instances running in correct region
- [ ] VPC and subnets created properly
- [ ] Security groups configured correctly
- [ ] Load balancer provisioned and healthy

### Application Testing
- [ ] Application URL accessible (from `terraform output`)
- [ ] Health endpoint responding: `/health`
- [ ] Guest endpoints working:
  - [ ] GET `/guests` returns empty list or existing guests
  - [ ] POST `/guests` accepts new guest data
  - [ ] Guest data validation working (Israeli phone format)

### Student Isolation Verification
- [ ] Unique cluster name confirmed
- [ ] Resources tagged with correct student name
- [ ] No conflicts with other student deployments
- [ ] Separate namespace: `guestlist-dev`

### API Functionality Tests
```powershell
# Replace [LB-URL] with your actual load balancer URL

# Test 1: Health check
curl http://[LB-URL]/health
# Expected: HTTP 200 OK

# Test 2: Get all guests  
curl http://[LB-URL]/guests
# Expected: JSON array (empty or with guests)

# Test 3: Add a test guest
curl -X POST http://[LB-URL]/guests -H "Content-Type: application/json" -d '{
  "firstname": "Test",
  "surname": "Student", 
  "quantity": "1",
  "phone": "0501234567",
  "email": "test@example.com",
  "guest_id": "TS2025"
}'
# Expected: Success response with guest details

# Test 4: Verify guest was added
curl http://[LB-URL]/guests
# Expected: JSON array including the test guest
```

### Performance & Monitoring
- [ ] Resource limits set on containers
- [ ] Liveness probes working (pods restart if unhealthy)
- [ ] Readiness probes working (traffic only to ready pods)
- [ ] Horizontal Pod Autoscaler configured
- [ ] Logs accessible: `kubectl logs -l app=guestlist -n guestlist-dev`

## 📊 Multi-Student Environment Verification

### Class-Wide Deployment Check
- [ ] All students can deploy simultaneously without conflicts
- [ ] Each student has unique cluster names
- [ ] AWS resource limits not exceeded
- [ ] Cost tracking possible per student via tags

### Verification Commands per Student
```powershell
# Check student's specific resources
aws eks describe-cluster --name guestlist-[student-name]-dev --region us-west-2

# List student's tagged resources  
aws resourcegroupstaggingapi get-resources --tag-filters Key=Owner,Values=[student-name]

# Check kubectl context
kubectl config current-context

# Verify student's namespace
kubectl get all -n guestlist-dev
```

## ⚠️ Common Issues Resolution

### Terraform Issues
- [ ] **Duplicate providers error**: Delete `terraform/providers.tf` file
- [ ] **State lock**: Wait or manually unlock if needed
- [ ] **Resource limits**: Check AWS service quotas
- [ ] **Naming conflicts**: Ensure unique cluster names

### kubectl Issues  
- [ ] **Connection refused**: Run kubectl config command from terraform output
- [ ] **Context issues**: Verify correct cluster context
- [ ] **Version compatibility**: Check kubectl version matches cluster

### Application Issues
- [ ] **Pods not starting**: Check node resources and image availability
- [ ] **Load balancer pending**: Wait 5-10 minutes for AWS provisioning
- [ ] **API not responding**: Check pod logs and service endpoints

### Cost Management Issues
- [ ] **Unexpected charges**: Verify all resources in correct region
- [ ] **Budget alerts**: Set up AWS billing notifications
- [ ] **Resource cleanup**: Ensure proper destruction of resources

## 🧹 Cleanup Verification

### Pre-Cleanup Checklist
- [ ] Important data backed up (logs, configurations)
- [ ] Final cost review completed
- [ ] Student specific resources identified
- [ ] Screenshot/documentation of working deployment saved

### Cleanup Process
- [ ] Run: `.\deploy.ps1 -UserName "[student-name]" -Environment dev -Destroy`
- [ ] Type 'yes' to confirm destruction
- [ ] Wait for all resources to be destroyed (5-15 minutes)
- [ ] Verify cleanup in AWS Console

### Post-Cleanup Verification
- [ ] EKS cluster removed from AWS Console
- [ ] EC2 instances terminated
- [ ] VPC and subnets cleaned up (if dedicated)
- [ ] Load balancers deleted
- [ ] No charges appearing in AWS billing for destroyed resources

## 📋 Success Criteria per Student

**Deployment is successful when:**
- ✅ Unique infrastructure provisioned with student name
- ✅ Application accessible via unique load balancer URL
- ✅ All API endpoints functional with proper validation
- ✅ Kubernetes pods healthy and auto-scaling configured  
- ✅ Resources properly tagged for cost tracking
- ✅ Estimated costs within expected range (~$151/month)

## 🎯 Student-Specific Success Examples

### Sivan's Success Criteria
- ✅ Cluster: `guestlist-sivan-dev`
- ✅ URL: `https://[unique-lb]-[region].elb.amazonaws.com`
- ✅ Tags: `Owner: sivan`
- ✅ Can add/retrieve guests via API

### Dvir's Success Criteria
- ✅ Cluster: `guestlist-dvir-dev`
- ✅ URL: Different from Sivan's URL
- ✅ Tags: `Owner: dvir`
- ✅ Independent scaling and configuration

### Saar's Success Criteria
- ✅ Cluster: `guestlist-saar-dev`
- ✅ URL: Unique load balancer endpoint
- ✅ Tags: `Owner: saar`
- ✅ Isolated from other student deployments

### Gili's Success Criteria
- ✅ Cluster: `guestlist-gili-dev`
- ✅ URL: Personal application endpoint
- ✅ Tags: `Owner: gili`
- ✅ Full CRUD operations working

## 📚 Learning Objectives Assessment

**DevSecOps Skills Demonstrated:**
- [ ] Infrastructure as Code with modular Terraform
- [ ] Container orchestration with Kubernetes
- [ ] Cloud security with AWS IAM, VPC, and Security Groups
- [ ] Cost optimization and management strategies
- [ ] Automated deployment with user isolation
- [ ] Multi-tenant architecture understanding
- [ ] Monitoring and observability implementation

**Student Collaboration Skills:**
- [ ] Resource sharing without conflicts
- [ ] Individual cost responsibility
- [ ] Isolated development environments
- [ ] Team-wide infrastructure patterns

## 📊 Final Documentation

### Document These Items per Student
- [ ] Final load balancer URL
- [ ] Cluster configuration used
- [ ] Total deployment time
- [ ] Any customizations or issues encountered
- [ ] Cost breakdown and optimizations applied
- [ ] Lessons learned and improvements suggested

### Class Summary
- [ ] All students successfully deployed
- [ ] Total class infrastructure cost estimate
- [ ] Common issues and resolutions
- [ ] Best practices identified
- [ ] Recommendations for future deployments

---

**📝 Deployment Notes:**
- Date: ___________
- Student Name: ___________
- Environment: ___________
- Cluster Name: ___________
- Final Status: ✅ Success / ❌ Issues
- Cleanup Completed: ✅ Yes / ❌ No

**🔄 Version:** 2.0 (Multi-Student Support)
**📅 Last Updated:** Current Date  
**👥 Validated For:** Sivan, Dvir, Saar, and Gili

Use this checklist for every deployment to ensure consistency, track individual student progress, and maintain proper cost controls across all deployments.
