terraform {
    backend "s3" {
        bucket = "tf-states-remote-backend"
        key = "tf-infra/web-app/terraform.tfstate"
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

variable "db_password_1" {
    type = string
    description = "The password for the first database user"
    sensitive = true
}

variable "db_password_2" {
    type = string
    description = "The password for the second database user"
    sensitive = true
}

module "web_application_1" {
  source = "../web-modules"

  # Pass input variables to the module
  domain = "abhishektriesterraform.com"
  app_name = "app1"
  environment = "production"
  instance_type = "t2.small"
  create_dns_zone = true
  db_name = "webappdb1"
  db_username = "admin"
  db_password = var.db_password_1
}

module "web_application_2" {
  source = "../web-modules"

  # Pass input variables to the module
  domain = "abhishektriestf.com"
  app_name = "app2"
  environment = "production"
  instance_type = "t2.small"
  create_dns_zone = true
  db_name = "webappdb2"
  db_username = "admin"
  db_password = var.db_password_2
}