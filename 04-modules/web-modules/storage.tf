# Using the existing bucket

data "aws_s3_bucket" "bucket" {
    bucket = "tf-states-remote-backend"
}