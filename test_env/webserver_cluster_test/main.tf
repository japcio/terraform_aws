provider "aws" {
    region = "eu-west-1"
}

module "webserver_cluster" {
    source ="../../modules/webserver-cluster"

    cluster_name            = "webservers-test"
    db_remote_state_bucket  = "terraform-current-state-japcio-aws"
    db_remote_state_key     = "../my_sql_test/terraform.tfstate"

    instance_type   = "t2.micro"
    min_size        = 2
    max_size        = 2 
}

