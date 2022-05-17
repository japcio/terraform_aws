#main file for terraform

provider "aws" {
    region="eu-west-1"
}


resource "aws_security_group" "instance" {
    name = "terraform-security-group"

    ingress {
        from_port   = 8080
        to_port     = 8080
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    ingress {
        from_port   = 22
        to_port     = 22
        protocol    = "tcp"
        cidr_blocks = [ "0.0.0.0/0" ]
    }
}
resource "aws_instance" "example" {
    ami = "ami-00c90dbdc12232b58"
    instance_type = "t2.micro"
    vpc_security_group_ids = [aws_security_group.instance.id]

    user_data = <<-EOF
              #!/bin/bash
              echo "Hello, World" > index.html
              nohup busybox httpd -f -p 8080 &
              EOF

    tags = {
        Name = "terraform_web_server"
    }

}

