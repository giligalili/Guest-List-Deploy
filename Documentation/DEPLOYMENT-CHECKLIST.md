# 📋 Deployment Checklist

Use this checklist to ensure successful deployment of your Guest List infrastructure.

## ✅ Pre-Deployment Checklist

### Prerequisites
- [ ] AWS CLI installed and configured
- [ ] Terraform installed (v1.0+)
- [ ] kubectl installed
- [ ] AWS credentials configured with proper permissions
- [ ] Git installed

### AWS Permissions Verification
- [ ] `AmazonEKSClusterPolicy`
- [ ] `AmazonEKSWorkerNodePolicy`
- [ ] `AmazonEKS_CNI_Policy`
- [ ] `AmazonEC2ContainerRegistryReadOnly`
- [ ] VPC and EC2 management permissions
- [ ] Load Balancer permissions

### Environment Configuration
- [ ] Environment file copied: `environments/dev/terraform.tfvars.local`
- [ ] Cluster name customized and unique
- [ ] Student name updated
- [ ] AWS region selected
- [ ] Instance types chosen for cost optimization
- [ ] Tags configured properly

## 🚀 Deployment Process

### Initial Setup
- [ ] Repository cloned successfully
- [ ] Navigate to project root directory
- [ ] Environment variables file configured

### Terraform Deployment
- [ ] `terraform init` completed successfully
- [ ] `terraform plan` shows expected resources
- [ ] `terraform apply` completed without errors
- [ ] All outputs displayed correctly

### Kubernetes Configuration
- [ ] kubectl configured with cluster credentials
- [ ] `kubectl get nodes` shows worker nodes
- [ ] `kubectl get pods -n guestlist-dev` shows running pods
- [ ] Load balancer service has external IP

### Application Verification
- [ ] API endpoint accessible via load balancer
- [ ] Health check endpoint responding: `/health`
- [ ] Guest endpoints working: `/guests`
- [ ] Can add new guest via POST request
- [ ] Can retrieve guests via GET request

## 🧪 Post-Deployment Testing

### Functional Tests
- [ ] API responds to GET /guests
- [ ] API accepts POST requests to add guests
- [ ] Health endpoint returns 200 OK
- [ ] Load balancer distributes traffic properly

### Infrastructure Tests
- [ ] All pods are running and ready
- [ ] Horizontal Pod Autoscaler is configured
- [ ] Services have proper endpoints
- [ ] ConfigMaps are mounted correctly

### Security Verification
- [ ] Pods run as non-root user
- [ ] Security groups restrict access properly
- [ ] IAM roles have minimal required permissions
- [ ] Network policies are in place

### Performance & Monitoring
- [ ] Resource limits are set on containers
- [ ] Liveness and readiness probes working
- [ ] Logs are accessible via kubectl
- [ ] Metrics endpoint available (if configured)

## 💰 Cost Management

### Cost Verification
- [ ] Review estimated monthly costs in terraform output
- [ ] Verify instance types are cost-appropriate
- [ ] Check node scaling configuration
- [ ] Monitor AWS billing dashboard

### Optimization
- [ ] Use t3.micro for testing (if performance allows)
- [ ] Set appropriate node capacity limits
- [ ] Consider spot instances for non-production
- [ ] Schedule auto-shutdown for development environments

## 🔍 Common Issues Checklist

### If Deployment Fails
- [ ] Check AWS credentials: `aws sts get-caller-identity`
- [ ] Verify IAM permissions are sufficient
- [ ] Ensure cluster name is unique
- [ ] Check region availability for chosen instance types
- [ ] Review terraform error messages for specifics

### If kubectl Doesn't Connect
- [ ] Run kubectl config command from terraform output
- [ ] Verify AWS CLI region matches terraform region
- [ ] Check if cluster is in "ACTIVE" state in AWS console
- [ ] Ensure kubectl version compatibility

### If Pods Don't Start
- [ ] Check node capacity: `kubectl describe nodes`
- [ ] Review pod logs: `kubectl logs -n guestlist-dev <pod-name>`
- [ ] Verify docker image is accessible
- [ ] Check resource requests vs available resources

### If Load Balancer Doesn't Work
- [ ] Wait 5-10 minutes for AWS provisioning
- [ ] Check service status: `kubectl get svc -n guestlist-dev`
- [ ] Verify security group rules allow traffic
- [ ] Test with node port if load balancer fails

## 🧹 Cleanup Verification

### Before Destroying
- [ ] Backup any important data or logs
- [ ] Document any custom configurations
- [ ] Note estimated costs for future reference
- [ ] Take screenshots of working deployment

### Destruction Process  
- [ ] Run `terraform destroy` command
- [ ] Confirm destruction when prompted
- [ ] Verify all resources deleted in AWS console
- [ ] Check for any remaining resources manually

### Post-Cleanup
- [ ] No charges appearing in AWS billing
- [ ] All EKS clusters removed
- [ ] All EC2 instances terminated
- [ ] VPC and subnets cleaned up
- [ ] Load balancers deleted

## 📊 Success Criteria

**Deployment is successful when:**
- ✅ All infrastructure provisioned without errors
- ✅ Application accessible via public load balancer
- ✅ All API endpoints functional
- ✅ Kubernetes pods healthy and running
- ✅ Estimated costs within expected range
- ✅ Security configurations properly applied

## 📚 Documentation

### Document These Items
- [ ] Final load balancer URL
- [ ] Cluster configuration used
- [ ] Total deployment time
- [ ] Any customizations made
- [ ] Lessons learned
- [ ] Cost breakdown

## 🎯 Learning Objectives Met

**DevSecOps Skills Demonstrated:**
- [ ] Infrastructure as Code with Terraform
- [ ] Container orchestration with Kubernetes
- [ ] Cloud security with AWS IAM and VPC
- [ ] Cost optimization strategies
- [ ] Automated deployment processes
- [ ] Monitoring and observability setup

---

**📝 Notes:**
Use this checklist for every deployment to ensure consistency and catch issues early.

**🔄 Version:** 1.0  
**📅 Last Updated:** $(date)  
**👤 Completed By:** [Your Name]  
**🎯 Environment:** [dev/staging/prod]
