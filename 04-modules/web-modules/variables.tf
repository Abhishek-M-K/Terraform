# Parameterized variables

# Region
variable "aws_region" {
  description = "The AWS region to deploy resources"
  type = string
  default = "us-east-1"
}

# Environment
variable "environment" {
  description = "The environment to deploy resources"
  type = string
  default = "dev"
}

# Application name
variable "app_name" {
  description = "The name of the application"
  type = string
  default = "web-app"
}

# AMI
variable "ami" {
  description = "The AMI to use for the EC2 instance"
  type = string
  default = "ami-011899242bb902164"
}

# Instance type
variable "instance_type" {
  description = "The instance type to use for the EC2 instance"
  type = string
  default = "t2.micro"
}

# AWS Route53 variables -> Domain | DNS
variable "domain" {
  description = "The domain name to use for the Route53 hosted zone"
  type = string
}



# AWS RDS variables
variable "db_name" {
  description = "The sample rds instance name"
  type = string
}

variable "db_username" {
  description = "The sample rds instance username"
  type = string
}

variable "db_password" {
  description = "The sample rds instance password"
  type = string
  sensitive = true
}

# Route 53 Variables
variable "create_dns_zone" {
  description = "If true, create new route53 zone, if false read existing route53 zone"
  type        = bool
  default     = false
}