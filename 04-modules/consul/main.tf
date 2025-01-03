terraform {
    backend "s3" {
        bucket = "tf-states-remote-backend"
        key = "tf-infra/modules/consul/terraform.tfstate"
        region = "us-east-1"
        dynamodb_table = "tf-state-locks"
        encrypt = true
    }

  required_providers {
    aws = {
        source  = "hashicorp/aws"
        version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

resource "aws_s3_bucket" "tf_states" {
    bucket = "tf-states-remote-backend"
    force_destroy = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "encryption" {
    bucket = aws_s3_bucket.tf_states.id
    rule {
        apply_server_side_encryption_by_default {
            sse_algorithm = "AES256"
        }
    }
}

resource "aws_s3_bucket_versioning" "versioning" {
    bucket = aws_s3_bucket.tf_states.id
    versioning_configuration {
        status = "Enabled"
    }
}

resource "aws_dynamodb_table" "tf_locks" {
    name = "tf-state-locks"
    billing_mode = "PAY_PER_REQUEST"
    hash_key = "LockID"
    attribute {
      name = "LockID"
      type = "S"
    }
}

# Module

module "consul" {
  source = "git::https://github.com/hashicorp/terraform-aws-consul.git"
}