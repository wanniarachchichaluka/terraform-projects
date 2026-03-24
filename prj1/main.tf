provider "aws" {
    region = "ap-south-1"
}

resource "aws_instance" "example" {
    ami = "ami-0ec10929233384c7f"
    instance_type = "t2.micro"
    subnet_id = "subnet-<id>"
    key_name= "<key pair name>" #to logging to EC2
}