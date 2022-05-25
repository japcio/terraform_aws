terraform {
  backend "s3" {
    bucket         = "terraform-current-state-japcio-aws"
    key            = "../../global_objects/s3_bucket/terraform.tfstate"
    region         = "eu-west-1"

    dynamodb_table = "terraform-locks"
    encrypt        = true
  }
}

provider "aws" {
    region = "eu-west-1"
}

module "webserver_cluster" {
    source ="../../modules/webserver-cluster"

    cluster_name            = var.cluster_name
    db_remote_state_bucket  = var.db_remote_state_bucket
    db_remote_state_key     = var.db_remote_state_key

    instance_type   = "t2.micro"
    min_size        = 2
    max_size        = 2 
}

