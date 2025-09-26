data "aws_iam_policy_document" "app_ddb_rw" {
  statement {
    actions = [
      "dynamodb:DescribeTable","dynamodb:Query","dynamodb:Scan",
      "dynamodb:GetItem","dynamodb:PutItem","dynamodb:UpdateItem",
      "dynamodb:DeleteItem","dynamodb:BatchGetItem","dynamodb:BatchWriteItem"
    ]
    resources = [ aws_dynamodb_table.guestlist_app.arn ]
  }
}

resource "aws_iam_policy" "app_ddb_rw" {
  name   = "guestlist-app-ddb-rw"
  policy = data.aws_iam_policy_document.app_ddb_rw.json
}