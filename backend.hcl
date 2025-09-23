bucket               = "YOUR-UNIQUE-STATE-BUCKET"   # e.g., "guest-list-terraform-state-dvir"
key                  = "envs/prod/terraform.tfstate"
region               = "us-east-1"               # match your AWS region
encrypt              = true
use_lockfile         = true                         # native S3 locking (no DynamoDB needed)
workspace_key_prefix = "envs"
