terraform {
  # ודא שה-Workflow רץ עם Terraform 1.10.x (למשל 1.10.8) או רכך את הדרישה.
  required_version = ">= 1.10.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }

  backend "s3" {
    bucket               = "guestlist-tfstate-bucket"
    key                  = "terraform.tfstate"   # key קצר; ה-workspace יתווסף בנתיב
    region               = "us-east-1"
    encrypt              = true
    dynamodb_table       = "terraform-locks"     # נעילה בטוחה
    workspace_key_prefix = "envs"                # state יישמר תחת: envs/<workspace>/terraform.tfstate
  }
}
