#!/bin/bash
# deploy.sh - Quick deployment script for Guest List API on EKS

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if required tools are installed
check_prerequisites() {
    print_status "Checking prerequisites..."
    
    # Check AWS CLI
    if ! command -v aws &> /dev/null; then
        print_error "AWS CLI is not installed. Please install it first."
        exit 1
    fi
    
    # Check Terraform
    if ! command -v terraform &> /dev/null; then
        print_error "Terraform is not installed. Please install it first."
        exit 1
    fi
    
    # Check kubectl
    if ! command -v kubectl &> /dev/null; then
        print_error "kubectl is not installed. Please install it first."
        exit 1
    fi
    
    # Check AWS credentials
    if ! aws sts get-caller-identity &> /dev/null; then
        print_error "AWS credentials not configured. Run 'aws configure' first."
        exit 1
    fi
    
    print_success "All prerequisites met!"
}

# Function to setup environment variables
setup_environment() {
    print_status "Setting up environment variables..."
    
    # Prompt for student name if not set
    if [ -z "$STUDENT_NAME" ]; then
        read -p "Enter your name (for resource tagging): " STUDENT_NAME
        if [ -z "$STUDENT_NAME" ]; then
            print_error "Student name is required!"
            exit 1
        fi
    fi
    
    # Set default values
    CLUSTER_NAME="${CLUSTER_NAME:-guestlist-${STUDENT_NAME,,}}"  # lowercase
    AWS_REGION="${AWS_REGION:-us-west-2}"
    ENVIRONMENT="${ENVIRONMENT:-dev}"
    
    # Create terraform.tfvars file
    cat > terraform.tfvars.local << EOF
# Auto-generated environment configuration
aws_region = "${AWS_REGION}"
cluster_name = "${CLUSTER_NAME}"
environment = "${ENVIRONMENT}"
student_name = "${STUDENT_NAME}"

# Cost-optimized defaults
node_instance_type = "t3.small"
node_desired_capacity = 2
node_max_capacity = 3
node_min_capacity = 1

app_image = "giligalili/guestlistapi:ver03"
app_replicas = 2
EOF
    
    print_success "Environment configured:"
    print_status "  Student Name: ${STUDENT_NAME}"
    print_status "  Cluster Name: ${CLUSTER_NAME}"
    print_status "  AWS Region: ${AWS_REGION}"
    print_status "  Environment: ${ENVIRONMENT}"
}

# Function to deploy infrastructure
deploy_infrastructure() {
    print_status "Initializing Terraform..."
    terraform init
    
    print_status "Planning deployment..."
    terraform plan -var-file="terraform.tfvars.local"
    
    print_warning "This will create AWS resources that incur costs (~$150/month)."
    read -p "Continue with deployment? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_status "Deployment cancelled."
        exit 0
    fi
    
    print_status "Applying Terraform configuration..."
    print_status "This will take 15-20 minutes for EKS cluster creation..."
    terraform apply -var-file="terraform.tfvars.local" -auto-approve
    
    print_success "Infrastructure deployed successfully!"
}

# Function to configure kubectl
configure_kubectl() {
    print_status "Configuring kubectl..."
    
    # Get kubectl config command from terraform output
    KUBECTL_CMD=$(terraform output -raw kubectl_config 2>/dev/null || echo "")
    
    if [ -z "$KUBECTL_CMD" ]; then
        KUBECTL_CMD="aws eks update-kubeconfig --region ${AWS_REGION} --name ${CLUSTER_NAME}"
    fi
    
    print_status "Running: $KUBECTL_CMD"
    eval $KUBECTL_CMD
    
    print_success "kubectl configured successfully!"
}

# Function to verify deployment
verify_deployment() {
    print_status "Verifying deployment..."
    
    # Wait for nodes to be ready
    print_status "Waiting for nodes to be ready..."
    kubectl wait --for=condition=Ready nodes --all --timeout=300s
    
    # Wait for pods to be running
    print_status "Waiting for application pods to be running..."
    kubectl wait --for=condition=Ready pods -l app=guestlist-api -n guestlist-${ENVIRONMENT} --timeout=300s
    
    # Get cluster info
    print_status "Cluster Nodes:"
    kubectl get nodes
    
    print_status "Application Pods:"
    kubectl get pods -n guestlist-${ENVIRONMENT}
    
    # Get service info
    print_status "Getting Load Balancer information..."
    kubectl get service guestlist-service -n guestlist-${ENVIRONMENT}
    
    # Get Load Balancer URL
    LB_HOST=$(terraform output -raw load_balancer_ip 2>/dev/null || echo "pending")
    
    if [ "$LB_HOST" != "pending" ] && [ ! -z "$LB_HOST" ]; then
        print_success "Load Balancer URL: http://${LB_HOST}"
        print_status "Testing API endpoint..."
        
        # Wait a bit for load balancer to be ready
        sleep 30
        
        if curl -f -s "http://${LB_HOST}/guests" > /dev/null; then
            print_success "API is responding successfully!"
            print_status "You can test your API with: curl http://${LB_HOST}/guests"
        else
            print_warning "API endpoint not yet ready. Wait a few minutes and try: curl http://${LB_HOST}/guests"
        fi
    else
        print_warning "Load Balancer is still provisioning. Check AWS Console or run:"
        print_status "kubectl get service guestlist-service -n guestlist-${ENVIRONMENT}"
    fi
}

# Function to show cost information
show_cost_info() {
    print_warning "=== COST INFORMATION ==="
    print_status "Estimated monthly costs for this deployment:"
    print_status "  - EKS Cluster: ~$72.00"
    print_status "  - EC2 Nodes (2x t3.small): ~$30.40"
    print_status "  - NAT Gateway: ~$32.40"
    print_status "  - Load Balancer: ~$16.20"
    print_status "  - Total: ~$151.00/month"
    print_warning ""
    print_warning "REMEMBER: Run 'terraform destroy' when done to avoid charges!"
    print_warning "Monitor your costs at: https://console.aws.amazon.com/billing/"
}

# Main deployment flow
main() {
    echo "=================================================="
    echo "🎉 Guest List API - EKS Deployment Script"
    echo "=================================================="
    
    check_prerequisites
    setup_environment
    deploy_infrastructure
    configure_kubectl
    verify_deployment
    show_cost_info
    
    print_success "🎉 Deployment completed successfully!"
    print_status ""
    print_status "Next steps:"
    print_status "1. Test your API: curl http://\$(terraform output -raw load_balancer_ip)/guests"
    print_status "2. Monitor your AWS costs"
    print_status "3. When done: terraform destroy -var-file=\"terraform.tfvars.local\""
}

# Handle script arguments
case "${1:-deploy}" in
    "deploy")
        main
        ;;
    "destroy")
        print_warning "This will destroy all resources and stop billing."
        read -p "Are you sure? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            terraform destroy -var-file="terraform.tfvars.local" -auto-approve
            print_success "Resources destroyed successfully!"
        fi
        ;;
    "status")
        kubectl get nodes
        kubectl get pods -n guestlist-${ENVIRONMENT:-dev}
        kubectl get service guestlist-service -n guestlist-${ENVIRONMENT:-dev}
        ;;
    *)
        echo "Usage: $0 [deploy|destroy|status]"
        echo "  deploy  - Deploy the infrastructure (default)"
        echo "  destroy - Destroy all resources"
        echo "  status  - Show current deployment status"
        exit 1
        ;;
esac
