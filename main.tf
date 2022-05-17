#main file for terraform

provider "aws" {
    region="eu-west-1"
}


resource "aws_instance" "example" {
    ami = "ami-00c90dbdc12232b58"
    instance_type = "t2.micro"

    tags = {
        Name = "terraform_example"
    }

}