terraform {
  required_version = ">= 0.8, < 0.12"
}

provider "aws" {
  region = "ap-southeast-1"
}

resource "aws_instance" "my-web-server" {
  ami           = "ami-6e2a1e12" #Ubuntu 16.04 LTS
  instance_type = "t2.micro"
  vpc_security_group_ids = ["${aws_security_group.my-web-asg.id}"]

  user_data = <<-EOF
              #!/bin/bash
              echo "Hello, World!" > index.html
              nohup busybox httpd -f -p "${var.server_port}" &
              EOF

  tags {
    Name = "my-web-server"
  }
}

resource "aws_security_group" "my-web-asg" {
    name = "my-web-asg"

    ingress {
      from_port = "${var.server_port}"
      to_port = "${var.server_port}"
      protocol = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
}

variable "server_port" {
  description = "The port that web server listen on"
  default = 8080
}

output "public_ip" {
  value = "${aws_instance.my-web-server.public_ip}"
}
