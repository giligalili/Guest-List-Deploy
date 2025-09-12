# terraform.tfvars
# Environment-specific variables - Copy and customize this file

# AWS Configuration
aws_region = "us-west-2"  # Change to your preferred region

# Cluster Configuration
cluster_name = "guestlist-cluster"  # Make this unique for each student
environment  = "dev"                # dev, staging, or prod

# Student Information (customize this!)
student_name = "sivan"     # Replace with your actual name

# Network Configuration
vpc_cidr = "10.0.0.0/16"

# Node Configuration (cost-optimized)
node_instance_type     = "t3.small"  # t3.micro is cheapest but may be too small
node_desired_capacity  = 2           # Start with 2 nodes
node_max_capacity      = 3           # Max 3 for cost control
node_min_capacity      = 1           # Min 1 to save costs when idle

# Application Configuration
app_image    = "giligalili/guestlistapi:ver04"  # Your Docker image
app_replicas = 2  # Start with 2 replicas, can scale up/down

# COST OPTIMIZATION NOTES:
# - Use t3.micro for cheapest option (may need more replicas)
# - Set node_desired_capacity = 1 for minimal cost
# - Consider using spot instances by changing capacity_type in eks.tf
# - Deploy in us-east-1 for lowest costs
# - Monitor usage and scale down when not needed
