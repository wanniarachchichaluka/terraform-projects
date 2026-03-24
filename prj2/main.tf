resource "aws_security_group" "jenkins_sg" {
  name        = "jenkins-sg"
  description = "security group for Jenkins CI/CD server"

  tags = {
    Name = "jenkins-sg"
  }
}

resource "aws_vpc_security_group_ingress_rule" "ssh" {
  security_group_id = aws_security_group.jenkins_sg.id

  cidr_ipv4   = "0.0.0.0/0"
  from_port   = 22
  ip_protocol = "tcp"
  to_port     = 22

  tags = {
    Name = "allow-ssh"
  }
}

resource "aws_vpc_security_group_ingress_rule" "jenkins_web" {
  security_group_id = aws_security_group.jenkins_sg.id

  cidr_ipv4   = "0.0.0.0/0"
  from_port   = 8080
  ip_protocol = "tcp"
  to_port     = 8080

  tags = {
    Name = "allow-jenkins-8080"
  }
}

resource "aws_vpc_security_group_ingress_rule" "jenkins_agents" {
  security_group_id = aws_security_group.jenkins_sg.id

  cidr_ipv4   = "0.0.0.0/0"
  from_port   = 50000
  ip_protocol = "tcp"
  to_port     = 50000

  tags = {
    Name = "allow-jenkins-agents-50000"
  }
}

resource "aws_vpc_security_group_ingress_rule" "staging" {
  security_group_id = aws_security_group.jenkins_sg.id

  cidr_ipv4   = "0.0.0.0/0"
  from_port   = 3000
  ip_protocol = "tcp"
  to_port     = 3000

  tags = {
    Name = "allow-staging-3000"
  }
}

resource "aws_vpc_security_group_ingress_rule" "production" {
  security_group_id = aws_security_group.jenkins_sg.id

  cidr_ipv4   = "0.0.0.0/0"
  from_port   = 80
  ip_protocol = "tcp"
  to_port     = 80

  tags = {
    Name = "allow-production-80"
  }
}

resource "aws_vpc_security_group_egress_rule" "allow_all_outbound" {
  security_group_id = aws_security_group.jenkins_sg.id

  cidr_ipv4   = "0.0.0.0/0"
  ip_protocol = "-1"

  tags = {
    Name = "allow-all-outbound"
  }
}

resource "aws_instance" "jenkins" {
  ami                         = "ami-05d2d839d4f73aafb" # Ubuntu 24.04 LTS for ap-south-1
  instance_type               = var.instance_type
  key_name                    = var.key_name
  vpc_security_group_ids      = [aws_security_group.jenkins_sg.id]
  associate_public_ip_address = true

  root_block_device {
    volume_size = 20
    volume_type = "gp3"
    encrypted   = true

    tags = {
      Name = "jenkins-server-root-volume"
    }
  }

  user_data = <<-EOF
    #!/bin/bash
    apt-get update -y
    apt-get install -y python3 python3-pip
    echo "Python3 installed for Ansible configuration"
  EOF

  tags = {
    Name = "jenkins-server"
  }
}

