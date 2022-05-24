provider "aws" {
    region = "eu-west-1"
  
}

resource "aws_s3_bucket" "terraform_state" {
    bucket="terraform-current-state-japcio-aws"

    #Prevent accidental deletion of this S3 bucket
    lifecycle {
      prevent_destroy = true
    }
}

#Enable versioning
resource "aws_s3_bucket_versioning" "enabled" {
  bucket = aws_s3_bucket.terraform_state.id
  versioning_configuration {
    status ="Enabled"
  }
  
}

#Enable server-side encryption by default
resource "aws_s3_bucket_server_side_encryption_configuration" "defaut" {
  bucket = aws_s3_bucket.terraform_state.id

  rule {
    apply_server_side_encryption_by_default{
      sse_algorithm = "AES256"
    }
  }
}


#Block public access to S3 bucket
resource "aws_s3_bucket_public_access_block" "example" {
  bucket = aws_s3_bucket.terraform_state.id
  block_public_acls = true
  block_public_policy = true
  ignore_public_acls  = true
  restrict_public_buckets = true
}

#DynamoDB will be used for locking
resource "aws_dynamodb_table" "terraform_locks" {
  name  = "terraform-locks"
  billing_mode  = "PAY_PER_REQUEST"
  hash_key      = "LockID"
  
  attribute {
    name  = "LockID"
    type  = "S"
  }
}

terraform {
  backend "s3" {
    bucket  = "terraform-current-state-japcio-aws"
    key     = "global/s3/terraform.tfstate"
    region  = "eu-west-1"

    dynamodb_table  = "terraform-locks"
    encrypt         = true
  }
}

variable "server_port" {
    description = "The port the server will use for HTTP requests"
    type        = number
    default = 8080
}

output "alb_dns_name" {
    value = aws_lb.example.dns_name
    description = "DNS name of the load balancer"
}


resource "aws_security_group" "instance" {
    name = "terraform-security-group"

    ingress {
        from_port   = var.server_port
        to_port     = var.server_port
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

#Security group for Application Load Balancer
resource "aws_security_group" "alb" {
    name = "terraform-example-alb"

    #Allow inbound HTTP requests
    ingress {
        from_port       = 80
        to_port         = 80
        protocol        = "tcp"
        cidr_blocks = ["0.0.0.0/0"] 
    }

    #Allow outbound requests
    egress {
        from_port   = 0
        to_port     = 0
        protocol    = "-1" #all protocols
        cidr_blocks = ["0.0.0.0/0"] 
    }
}

data "aws_vpc" "default" {
    default = true
}

data "aws_subnets" "default" {
    filter {
        name    = "vpc-id"
        values  = [data.aws_vpc.default.id]
    }
}

resource "aws_launch_configuration" "example" {
    image_id = "ami-00c90dbdc12232b58"
    instance_type = "t2.micro"
    security_groups = [aws_security_group.instance.id]

    user_data = templatefile("user_data.sh", {
      server_port = var.server_port
      db_address  = data.terraform_remote_state.db.outputs.address
      db_port     = data.terraform_remote_state.db.outputs.port
    })
    

# Required when using a launch configuration with an auto scaling group.
    lifecycle {
      create_before_destroy = true
    }

}


resource "aws_autoscaling_group" "example" {
    launch_configuration    = aws_launch_configuration.example.name
    vpc_zone_identifier     = data.aws_subnets.default.ids 

    target_group_arns = [aws_lb_target_group.asg.arn]
    health_check_type ="ELB"

    min_size = 2
    max_size = 10

    tag {
        key     = "Name"
        value   ="terraform-asg-example"
        propagate_at_launch = true
    }
}

resource "aws_lb" "example" {
    name                = "terraform-asg-example"
    load_balancer_type  = "application"
    subnets             = data.aws_subnets.default.ids
    security_groups     = [aws_security_group.alb.id]
}

resource "aws_lb_target_group" "asg" {
  name  = "terraform-asg-example"
  port  =   var.server_port
  protocol  = "HTTP"
  vpc_id    = data.aws_vpc.default.id

  health_check {
    path        = "/"
    protocol    = "HTTP"
    matcher     = "200"
    interval    = 15
    timeout     =3 
    healthy_threshold   =  2
    unhealthy_threshold = 2
  }
}
resource "aws_lb_listener" "http" {
    load_balancer_arn   = aws_lb.example.arn
    port                = 80
    protocol            = "HTTP"

    #By default show a simple 404 page
    default_action {
        type = "fixed-response"
            fixed_response {
            content_type    = "text/plain"
            message_body    = "404: page not found"
            status_code = 404
        }
    }
}

resource "aws_lb_listener_rule" "asg" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 100

  condition {
    path_pattern {
      values = ["*"]
    }
  }

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.asg.arn
  }
}



output "s3_bucker_arn" {
  value = aws_s3_bucket.terraform_state.arn
  description = "The ARN of the s3 bucket"
}

output "dynamodb_table_name" {
  value = aws_dynamodb_table.terraform_locks.name
  description ="The name of the DynamoDB table"
}


data "terraform_remote_state" "db" {
  backend = "s3"

  config = {
    bucket = "terraform-current-state-japcio-aws"
    key    = "data-stores/mysql/terraform.tfstate"
    region = "eu-west-1"
  }
}