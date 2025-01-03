# This file is used to create the infrastructure resources. 
# This resources can be used directly in the main.tf file or can be used as a module in the main.tf file.

resource "aws_instance" "sample1" {
    ami = var.ami
    instance_type = var.instance_type
    security_groups = [aws_security_group.instances.name]
    user_data = <<-EOF
                #!/bin/bash
                echo "Hello All, Abhishek here! Nothing just playing with Terraform 😄" > index.html
                python3 -m http.server 8080 &
                EOF
}

resource "aws_instance" "sample2" {
    ami = var.ami
    instance_type = var.instance_type
    security_groups = [aws_security_group.instances.name]
    user_data = <<-EOF
                #!/bin/bash
                echo "Hello All, Abhishek here! Terraform is fun 😄" > index.html
                python3 -m http.server 8080 &
                EOF
}