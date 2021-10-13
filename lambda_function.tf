resource "aws_lambda_function" "lambda_tf" {
  filename      = "lambda.zip"
  function_name = "lambda_handler"
  role          = "${aws_iam_role.iam_for_lambda.arn}"
  handler       = "lambda.lambda_handler"

  # The filebase64sha256() function is available in Terraform 0.11.12 and later
  # For Terraform 0.11.11 and earlier, use the base64sha256() function and the file() function:
  # source_code_hash = "${base64sha256(file("lambda_function_payload.zip"))}"
  source_code_hash = filebase64sha256("lambda.zip")
  runtime = "python2.7"
  depends_on = ["aws_iam_role.iam_for_lambda"]
}

resource "aws_iam_role" "iam_for_lambda" {
  name = "iam_for_lambda"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
POLICY
}

#cloudwatch log for lambda function
resource "aws_cloudwatch_log_group" "lambda_log_group" {
  name = "/aws/lambda/${aws_lambda_function.lambda_tf.function_name}"
  retention_in_days = 14
  depends_on = [
    aws_lambda_function.lambda_tf
  ]
}
#lambda want to stream the logs to cloudwatch
resource "aws_iam_policy" "lambda_logging" {
    name = "lambda_logging"
    path = "/"
    description = "IAM policy for logging from lambda"
    policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": "arn:aws:logs:*:*:*",
      "Effect": "Allow"
    }
  ]
}
EOF
}
#i need to attach the iam role with lambda loggin
resource "aws_iam_role_policy_attachment" "lambda_logs" {
  role       = "${aws_iam_role.iam_for_lambda.name}"
  policy_arn = "${aws_iam_policy.lambda_logging.arn}"
}

#printout the lambda function
output "lambda_function_details" {
  value = "${aws_lambda_function.lambda_tf}"
}