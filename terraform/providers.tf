# Provider Configurations

terraform {
  required_version = ">= 1.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.23"
    }
    
    random = {
      source  = "hashicorp/random"
      version = "~> 3.1"
    }
  }

  # Uncomment and configure for remote state management
  # backend "s3" {
  #   bucket = "your-terraform-state-bucket"
  #   key    = "guestlist/terraform.tfstate"
  #   region = "us-west-2"
  #   
  #   # For state locking
  #   dynamodb_table = "terraform-state-locks"
  #   encrypt        = true
  # }
}
