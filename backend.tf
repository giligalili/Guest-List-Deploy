terraform {
  backend "s3" {
    bucket = "guest-list-terraform-state-bucket"     
    key    = "dev/terraform.tfstate"              
    region = "us-east-1"                          
    encrypt = true                               
    dynamodb_table = "terraform-lock-table"        
  }
}
