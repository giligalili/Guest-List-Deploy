resource "aws_dynamodb_table" "guestlist_app" {
  name         = local.ddb_table_name
  billing_mode = "PAY_PER_REQUEST"

  hash_key = "id"

  attribute {
    name = "id"
    type = "S"
  }

  tags = {
    Project     = "guest-list"
    Environment = var.environment
    Student     = var.environment
  }
}
