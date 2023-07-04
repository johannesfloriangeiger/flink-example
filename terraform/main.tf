resource "aws_s3_bucket" "bucket" {
  bucket = var.bucket
}

data "aws_iam_policy_document" "flink-assume-policy-document" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["kinesisanalytics.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "flink-role" {
  name               = "flink-role"
  assume_role_policy = data.aws_iam_policy_document.flink-assume-policy-document.json
}

data "aws_iam_policy_document" "flink-policy-document" {
  statement {
    actions = [
      "s3:GetObject",
      "s3:GetObjectVersion",
      "s3:GetBucket*",
      "s3:List*",
      "s3:ListBucket",
      "s3:PutObject",
      "s3:Abort*",
      "s3:DeleteObject*"
    ]
    resources = [
      "arn:aws:s3:::${aws_s3_bucket.bucket.bucket}/flink-application.jar",
      "arn:aws:s3:::${aws_s3_bucket.bucket.bucket}",
      "arn:aws:s3:::${aws_s3_bucket.bucket.bucket}/*"
    ]
  }
}

resource "aws_iam_policy" "flink-policy" {
  name   = "flink-policy"
  policy = data.aws_iam_policy_document.flink-policy-document.json
}

resource "aws_iam_role_policy_attachment" "flink-policy-attachment" {
  role       = aws_iam_role.flink-role.name
  policy_arn = aws_iam_policy.flink-policy.arn
}

resource "aws_s3_object" "flink-application" {
  bucket = aws_s3_bucket.bucket.id
  key    = "flink-application.jar"
  source = "../target/flink-example-1.0-SNAPSHOT.jar"
  etag   = filemd5("../target/flink-example-1.0-SNAPSHOT.jar")
}

resource "aws_kinesisanalyticsv2_application" "application" {
  name                   = "flink-application"
  runtime_environment    = "FLINK-1_15"
  service_execution_role = aws_iam_role.flink-role.arn

  application_configuration {
    application_code_configuration {
      code_content {
        s3_content_location {
          bucket_arn = aws_s3_bucket.bucket.arn
          file_key   = aws_s3_object.flink-application.key
        }
      }

      code_content_type = "ZIPFILE"
    }

    environment_properties {
      property_group {
        property_group_id = "FlinkApplicationProperties"

        property_map = {
          bucket = aws_s3_bucket.bucket.bucket
        }
      }
    }
  }
}