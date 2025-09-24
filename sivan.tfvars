# Sivan's configuration
cluster_name          = "guestlist-sivan"
student_name          = "sivan"
environment          = "dev"
aws_region           = "us-east-1"

# Cost optimization settings
node_instance_type   = "t3.small"
node_desired_capacity = 2
node_max_capacity    = 3
node_min_capacity    = 1

# Application settings
app_image            = "giligalili/guestlistapi:ver04"
app_replicas         = 3

# VPC Configuration (optional - using defaults)
vpc_cidr             = "10.0.0.0/16"