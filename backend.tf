terraform {
  backend "s3" {
    bucket         = "guestlist-tfstate-sivan"
    key            = "terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-locks-sivan"
    encrypt        = true
  }
}