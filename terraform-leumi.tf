provider "aws" {
  region = "us-east-1"
}

resource "aws_instance" "web_server" {
  ami           = "ami-0f55e373" # Amazon Linux 2 LTS
  instance_type = "t2.micro"

  tags = {
    Name = "web_server"
  }

  connection {
    type        = "ssh"
    user        = "ec2-user"
    private_key = file("~/.ssh/id_rsa")
  }

  provisioner "remote-exec" {
    inline = [
      "sudo yum install -y httpd",
      "sudo systemctl start httpd",
      "sudo systemctl enable httpd",
    ]
  }
}

resource "aws_security_group" "web_server_sg" {
  name        = "web_server_sg"
  description = "Allow incoming traffic from 91.231.245.50 only"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["91.231.245.50/32"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_network_load_balancer" "web_server_nlb" {
  name                = "web_server_nlb"
  internal            = false
  load_balancer_type  = "network"

  subnets = aws_subnet.public.*.id

  listener {
    port     = 80
    protocol = "TCP"

    default_action {
      target_group_arn = aws_lb_target_group.web_server_tg.arn
      type             = "forward"
    }
  }
}

resource "aws_lb_target_group" "web_server_tg" {
  name     = "web_server_tg"
  port     = 80
  protocol = "TCP"

  target {
    id = aws_instance.web_server.id
  }
}
