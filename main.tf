resource "aws_instance" "webserver"{
    ami = "ami-01e7ca2ef94a0ae86"
    instance_type = "t2.micro"
    vpc_security_group_ids = [ aws_security_group.websg.id ]

    user_data = <<-EOF
        #!/bin/bash
        echo "Good Morning Rajeev." > index.html
        nohup busybox httpd -f -p 80 &
        EOF
  tags = {
    "Name" = "WEBSERVER-RAJEEV"
  }
}

output "webserveripaddress" {
    value = aws_instance.webserver.public_ip
}

resource "aws_security_group" "websg"{
    name = "rajeevsggroup"

    ingress {
      cidr_blocks = [ "0.0.0.0/0" ]
      description = "ingress"
      from_port = 80
      protocol = "tcp"
      to_port = 80
    }

    ingress {
      cidr_blocks = [ "0.0.0.0/0" ]
      description = "ingress"
      from_port = 22
      protocol = "tcp"
      to_port = 22
    }
}