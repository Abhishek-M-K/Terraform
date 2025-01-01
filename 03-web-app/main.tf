# Producing the infrastructure as depicted in the architecture.png 

terraform{
    #step 2
    backend "s3" {
        bucket = "tf-states-remote-backend"
        key = "tf-infra/terraform.tfstate"
        region = "us-east-1"
        dynamodb_table = "tf-state-locks"
        encrypt = true
    }

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

resource "aws_instance" "sample1" {
    ami = "ami-011899242bb902164" # Ubuntu 20.04 LTS x86_64
    instance_type = "t2.micro"
    security_groups = [aws_security_group.application_group.name]
    user_data = <<-EOF
                #!/bin/bash
                echo "Hello All, Abhishek here! Nothing just playing with Terraform 😄" > index.html
                python3 -m http.server 8080 &
                EOF
}

resource "aws_instance" "sample2" {
    ami = "ami-011899242bb902164" # Ubuntu 20.04 LTS x86_64
    instance_type = "t2.micro"
    security_groups = [aws_security_group.application_group.name]
    user_data = <<-EOF
                #!/bin/bash
                echo "Hello All, Abhishek here! Terraform is fun 😄" > index.html
                python3 -m http.server 8080 &
                EOF
}


# Resources for remote backend
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


# Resources for the application
data "aws_vpc" "default_vpc" {
  default = true
}

data "aws_subnets" "default_subnet" {
#   vpc_id = data.aws_vpc.default_vpc.id
    filter {
      name = "vpc-id"
      values = [data.aws_vpc.default_vpc.id]
    }
}

resource "aws_security_group" "application_group" {
    name = "application_group"
}

# Ingress rule -> Allow HTTP reqs to the instances
resource "aws_security_group_rule" "allow_http_requests" {
  type = "ingress"
  security_group_id = aws_security_group.application_group.id
  from_port = 8080
  to_port = 8080
  protocol = "tcp"
  cidr_blocks = [ "0.0.0.0/0" ] # Allow from all IPs
}

# Load balancer
resource "aws_security_group" "lb_group" {
    name = "lb_group"
}

resource "aws_lb" "load_balancer" {
  name = "sample-lb"
  load_balancer_type = "application"
  subnets = data.aws_subnets.default_subnet.ids
  security_groups = [aws_security_group.lb_group.id]
}

resource "aws_lb_listener" "http_listener" {
  load_balancer_arn = aws_lb.load_balancer.arn
  port = 80
  protocol = "HTTP"

  # Default action -> Send 404 Error Page
  default_action {
    type = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      message_body = "404: Looks like you're lost!"
      status_code = "404"
    }
  }
}

resource "aws_lb_target_group" "application_target_group" {
  name = "sample-target-group"
  port = 8080
  protocol = "HTTP"
  target_type = "instance"
  vpc_id = data.aws_vpc.default_vpc.id

  # Health check 
  health_check {
    path = "/"
    protocol = "HTTP"
    port = "8080"
    matcher = "200"
    interval = 10
    timeout = 5
    healthy_threshold = 2
    unhealthy_threshold = 2 
  }
}

resource "aws_lb_target_group_attachment" "application_instance_1" {
    target_group_arn = aws_lb_target_group.application_target_group.arn
    target_id = aws_instance.sample1.id
    port = 8080
}

resource "aws_lb_target_group_attachment" "application_instance_2" {
    target_group_arn = aws_lb_target_group.application_target_group.arn
    target_id = aws_instance.sample2.id
    port = 8080
}

resource "aws_lb_listener_rule" "application_instances" {
    listener_arn = aws_lb_listener.http_listener.arn
    priority = 100 # Lower the number, higher the priority
    condition {
      path_pattern {
        values = [ "*" ]
      }
    }
    action {
      type = "forward"
      target_group_arn = aws_lb_target_group.application_target_group.arn
    }
}

# Ingress rule -> Allow HTTP reqs to the load balancer
resource "aws_security_group_rule" "lb_incoming_req" {
    type = "ingress"
    security_group_id = aws_security_group.lb_group.id
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = [ "0.0.0.0/0" ]
}

# Egress rule -> Allow all traffic from the load balancer Eg: To any external APIs
resource "aws_security_group_rule" "lb_outgoing_reqs" {
  type = "egress"
  security_group_id = aws_security_group.lb_group.id
  from_port = 0
  to_port = 0
  protocol = "-1"
  cidr_blocks = [ "0.0.0.0/0" ]
}

# ROUTE 53 is a managed DNS service provided by AWS for translating domain names to IP addresses and vice versa.
resource "aws_route53_zone" "primary" {
  name = "abhishekkhandare.dev"
}

resource "aws_route53_record" "root" {
  zone_id = aws_route53_zone.primary.zone_id
  name = "abhishekkhandare.dev"
  type = "A"

  alias {
    name = aws_lb.load_balancer.dns_name
    zone_id = aws_lb.load_balancer.zone_id
    evaluate_target_health = true
  }
}

# AWS RDS 
resource "aws_db_instance" "sample_db" {
    db_name = "sampledbforfun"
    instance_class = "db.t3.micro"
    allocated_storage = 10 # 10 GB
    storage_type = "standard"
    engine = "mysql"
    engine_version = "5.7"
    username = "admin"
    password = var.db_password
    skip_final_snapshot = true # Don't take a snapshot when the instance is deleted (Snapshot is a backup of the database)
}