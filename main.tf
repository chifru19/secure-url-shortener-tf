resource "aws_dynamodb_table" "url_db" { name = "urls"; hash_key = "id"; attribute { name = "id"; type = "S" } }
resource "aws_lambda_function" "redirect_logic" { filename = "lambda.zip"; function_name = "url_redirector"; role = "arn:aws:iam::12345:role/lambda_role"; handler = "index.handler"; runtime = "nodejs18.x" }
