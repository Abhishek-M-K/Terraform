terraform{
    required_providers {
      aws = {
        source = "hashicorp/aws"
        version = "~> 5.0"
      }
    }
}

provider "aws" {
  region = "us-east-1"
}

resource "aws_instance" "test" {
    ami = "ami-011899242bb902164" # Ubuntu 20.04 LTS x86_64
    instance_type = "t2.micro"
}