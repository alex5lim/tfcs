terraform {
  required_version = ">= 0.8, < 0.12"
}

provider "aws" {
  region = "ap-southeast-1"
}

resource "aws_instance" "example" {
  ami           = "ami-8e0205f2"
  instance_type = "t2.micro"

  tags {
    Name = "my-wordpress-server"
  }
}
