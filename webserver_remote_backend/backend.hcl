#backend.hcl

bucket          = "terraform-current-state-japcio-aws"
region          = "eu-west-1"
dynamodb_table  = "terraform-locks"
encrypt         = true