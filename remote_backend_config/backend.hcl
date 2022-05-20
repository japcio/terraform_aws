#backend.hcl

bucket          = "terraform-current-state-japcio"
region          = "eu-west-1"
dynamodb_table  = "terraform-locks"
encrypt         = true