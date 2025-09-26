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

resource "aws_iam_user_policy_attachment" "attach_app_ddb" {
  count      = length(var.app_iam_user_name) > 0 ? 1 : 0
  user       = var.app_iam_user_name
  policy_arn = aws_iam_policy.app_ddb_rw.arn
}
