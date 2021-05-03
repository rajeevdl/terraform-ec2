resource "aws_instance" "webserver" {
  count = 2
  ami                    = "ami-01e7ca2ef94a0ae86"
  instance_type          = "t2.micro"
  vpc_security_group_ids = [aws_security_group.websg.id]

  user_data = <<-EOF
        #!/bin/bash
        echo "Good Morning Rajeev - "`hostname` > index.html
        nohup busybox httpd -f -p 80 &
        EOF
  tags = {
    "Name" = var.ec2-tags[count.index]
  }

  key_name = "rajeev-key"

  provisioner "local-exec" {
    command = "echo ${self.public_ip} >> ipaddress.txt"
  }

  provisioner "local-exec" {
    command = "echo ${self.private_ip} >> ipaddress.txt"
  }

  provisioner "file" {
    source      = "listing.sh"
    destination = "/tmp/listing.sh"
    connection {
      type        = "ssh"
      host        = self.public_ip
      user        = "ubuntu"
      private_key = file("./rajeev-key.pem")
    }
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/listing.sh",
      "/tmp/listing.sh"
    ]
    connection {
      type        = "ssh"
      host        = self.public_ip
      user        = "ubuntu"
      private_key = file("./rajeev-key.pem")
    }
  }
}

output "webserveripaddress" {
  value = aws_instance.webserver[*].public_ip
}

resource "aws_security_group" "websg" {
  name = "rajeevsggroup"

  ingress {
    cidr_blocks = ["0.0.0.0/0"]
    description = "ingress"
    from_port   = 80
    protocol    = "tcp"
    to_port     = 80
  }

  ingress {
    cidr_blocks = ["0.0.0.0/0"]
    description = "ingress"
    from_port   = 22
    protocol    = "tcp"
    to_port     = 22
  }
}

variable "ec2-tags" {
  default = ["WEBSERVER-RAJEEV-1","WEBSERVER-RAJEEV-2"]
  description = "Tags for EC2 Instances"
}

resource "aws_security_group" "albsg"{
  name = "rajeevalb"
  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_alb" "mylb" {
  name = "rajeev-lb"
  internal = false
  load_balancer_type = "application"
  subnets = var.public_subnet_ids
  security_groups = [aws_security_group.albsg.id]
}

resource "aws_lb_target_group" "myalbtg" {
  name = "rajeev-tg"
  port = 80
  protocol = "HTTP"
  vpc_id = var.vpc_id
 }

 resource "aws_alb_target_group_attachment" "awsaltgatc" {
   count = var.webserver_count
   target_group_arn = aws_lb_target_group.myalbtg.arn
   target_id = aws_instance.webserver[count.index].id
 }

resource "aws_lb_listener" "mylblistener" {
 load_balancer_arn = aws_alb.mylb.arn
 port = 80
 protocol = "HTTP"

 default_action {
   type = "forward"
   target_group_arn = aws_lb_target_group.myalbtg.arn
 }
}

output "albdns" {
  value = aws_alb.mylb.dns_name
}
