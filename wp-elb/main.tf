terraform {
  required_version = ">= 0.8, < 0.12"
}

provider "aws" {
  region = "ap-southeast-1"
}

resource "aws_security_group" "web-elb-asg" {
    name = "web-elb-asg"

    ingress {
      from_port   = "${var.elb_port}"
      to_port     = "${var.elb_port}"
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }

    egress {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
    }
}

resource "aws_security_group" "web-asg" {
    name = "web-asg"

    # allow web
    ingress {
      from_port   = "${var.server_port}"
      to_port     = "${var.server_port}"
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }

    # allow ssh
    ingress {
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }

    # allow monit
    ingress {
      from_port   = 2812
      to_port     = 2812
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }

    egress {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
    }
}

resource "aws_instance" "web-server" {
  # ami           = "ami-6e2a1e12" #Ubuntu 16.04 LTS
  ami           = "ami-f8370b84"   #Wordpress Certified by Bitnami
  instance_type = "t2.micro"
  vpc_security_group_ids = ["${aws_security_group.web-asg.id}"]

  # SSH key name
  key_name = "MyShinyEC2Key"

  # installation script
  user_data = "${data.template_file.user-data.rendered}"
  tags {
    Name = "web-server"
  }
}

resource "aws_elb" "web-elb" {
    name               = "web-elb"
    availability_zones = ["${data.aws_availability_zones.all.names}"]
    security_groups    = ["${aws_security_group.web-elb-asg.id}"]

    listener {
      lb_port           = "${var.elb_port}"
      lb_protocol       = "http"
      instance_port     = "${var.server_port}"
      instance_protocol = "http"
    }

    health_check {
      healthy_threshold = 2
      unhealthy_threshold = 2
      timeout = 3
      target = "HTTP:${var.server_port}/"
      interval = 30
    }

    instances = ["${aws_instance.web-server.id}"]
}

data "aws_availability_zones" "all" {}

data "template_file" "user-data" {
  template = "${file("user-data.sh")}"

  vars {
    server_port = "${var.server_port}"
  }
}

variable "ssh_key_name" {
  description = "Name of SSH key for EC2 instance"
  default = "MyShinyEC2Key"
}
variable "server_port" {
  description = "The port that web server listen on"
  default = 80
}

variable "elb_port" {
  description = "The port that elb listen on"
  default = 80
}

output "web_server_dns_name" {
  value = "${aws_instance.web-server.public_dns}"
}
output "elb_dns_name" {
  value = "${aws_elb.web-elb.dns_name}"
}
