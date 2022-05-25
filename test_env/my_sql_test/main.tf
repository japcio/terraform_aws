terraform {
  backend "s3" {
    bucket         = "terraform-current-state-japcio-aws"
    key            = "../../global_objects/s3_bucket/terraform.tfstate"
    region         = "eu-west-1"

    dynamodb_table = "terraform-locks"
    encrypt        = true
  }
}

provider "aws"{
    region  =   "eu-west-1"
}

resource "aws_db_instance" "example" {
    identifier_prefix   = "terraform-japcio"
    engine              = "mysql"
    allocated_storage   = 10
    instance_class      = "db.t2.micro"
    db_name             = var.db_name
    skip_final_snapshot = "true"
    
    username = var.db_username
    password = var.db_password
}

