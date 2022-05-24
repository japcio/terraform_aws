provider "aws"{
    region  =   "eu-west-1"
}

resource "aws_db_instance" "example" {
    identifier_prefix   = "terraform-japcio"
    engine              = "mysql"
    allocated_storage   = 10
    instance_class      = "db.t2.micro"
    db_name             = "example_database"
    skip_final_snapshot = "true"
    
    username = var.db_username
    password = var.db_password
}


terraform {
  backend "s3" {
    bucket  = "terraform-current-state-japcio-aws"
    key     = "data-stores/mysql/terraform.tfstate"
    region  = "eu-west-1"

    dynamodb_table  = "terraform-locks"
    encrypt         = true
  }
}
