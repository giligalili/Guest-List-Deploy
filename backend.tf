terraform {
  # אם ה־workflow שלך היום על 1.9.8, השתמש בדרישה תואמת.
  # אפשרות 1: להשאיר 1.9.8 ב־YAML ולהגדיר טווח שתואם:
  required_version = ">= 1.10.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }

  backend "s3" {
    bucket               = "guestlist-tfstate-bucket"
    key                  = "terraform.tfstate"   # key קצר; ה־workspace יתווסף בנתיב
    region               = "us-east-1"
    encrypt              = true
    dynamodb_table       = "terraform-locks"     # נעילה בטוחה
    workspace_key_prefix = "envs"                # יישמר תחת: envs/<workspace>/terraform.tfstate
  }
}
