terraform {
  required_version = ">= 0.8, < 0.12"
}

provider "aws" {
  region = "ap-southeast-1"
}

resource "aws_elb" "web-elb" {
    name               = "ha-web-elb"
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
}

resource "aws_launch_configuration" "my-ha-web" {
    image_id        = "ami-6e2a1e12" #Ubuntu 16.04 LTS
    instance_type   = "t2.micro"
    security_groups = ["${aws_security_group.my-web-asg.id}"]

    user_data = <<-EOF
                #!/bin/bash
                echo "Hello, World!" > index.html
                nohup busybox httpd -f -p "${var.server_port}" &
                EOF

    lifecycle {
      create_before_destroy = true
    }

}
resource "aws_autoscaling_group" "my-ha-web" {
    launch_configuration = "${aws_launch_configuration.my-ha-web.id}"
    availability_zones   = ["${data.aws_availability_zones.all.names}"]

    load_balancers = ["${aws_elb.web-elb.id}"]
    health_check_type = "ELB"

    min_size = 2
    max_size = 10

    tag {
      key                 = "Name"
      value               = "my-ha-web"
      propagate_at_launch = true
    }
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
resource "aws_security_group" "my-web-asg" {
    name = "my-web-asg"

    ingress {
      from_port   = "${var.server_port}"
      to_port     = "${var.server_port}"
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }

    lifecycle {
      create_before_destroy = true
    }
}

data "aws_availability_zones" "all" {}

variable "server_port" {
  description = "The port that web server listen on"
  default = 8080
}

variable "elb_port" {
  description = "The port that elb listen on"
  default = 80
}

output "elb_dns_name" {
  value = "${aws_elb.web-elb.dns_name}"
}
