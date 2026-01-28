# Provider Configuration

provider "aws" {
  region = "us-east-1"
}


# Key Pair

resource "aws_key_pair" "key_pair" {
  key_name   = "MyKey"
  public_key = file("~/.ssh/id_rsa.pub")
}


# VPC

resource "aws_vpc" "prod" {
  cidr_block           = "172.20.0.0/16"
  enable_dns_hostnames = true

  tags = {
    Name = "prod-vpc"
  }
}


# Public Subnet

resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.prod.id
  cidr_block              = "172.20.10.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "public-subnet"
  }
}


# Internet Gateway

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.prod.id

  tags = {
    Name = "prod-igw"
  }
}


# Route Table

resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.prod.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "public-route-table"
  }
}


# Route Table Association

resource "aws_route_table_association" "public_rt_assoc" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_rt.id
}


# Security Group - Jenkins

resource "aws_security_group" "jenkins_sg" {
  name        = "jenkins-sg"
  description = "Security group for Jenkins Server"
  vpc_id      = aws_vpc.prod.id

  ingress {
    description = "Jenkins UI"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "SonarQube"
    from_port   = 9000
    to_port     = 9000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "jenkins-sg"
  }
}


# Security Group - App Server

resource "aws_security_group" "app_sg" {
  name        = "app-sg"
  description = "Security group for App Server"
  vpc_id      = aws_vpc.prod.id

  ingress {
    description = "Application Port"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "app-sg"
  }
}


# Jenkins EC2 Instance

resource "aws_instance" "jenkins" {
  ami                    = "ami-0fa3fe0fa7920f68e"
  instance_type          = "t2.large"
  subnet_id              = aws_subnet.public_subnet.id
  key_name               = aws_key_pair.key_pair.key_name
  vpc_security_group_ids = [aws_security_group.jenkins_sg.id]

  connection {
    type        = "ssh"
    host        = self.public_ip
    user        = "ec2-user"
    private_key = file("~/.ssh/id_rsa")
  }

  provisioner "remote-exec" {
    inline = [
      "sudo yum update -y",
      "sudo yum install git maven ansible docker wget -y",
      "sudo systemctl start docker",
      "sudo systemctl enable docker",
      "sudo usermod -aG docker ec2-user",

      "sudo wget -O /etc/yum.repos.d/jenkins.repo https://pkg.jenkins.io/redhat-stable/jenkins.repo",
      "sudo rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io-2023.key",
      "sudo yum install jenkins -y",
      "sudo systemctl enable jenkins",
      "sudo systemctl start jenkins",

      "sudo docker run -d --name sonar -p 9000:9000 sonarqube"
    ]
  }

  tags = {
    Name = "Jenkins-Server"
  }
}


# App EC2 Instance

resource "aws_instance" "app" {
  ami                    = "ami-0fa3fe0fa7920f68e"
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.public_subnet.id
  key_name               = aws_key_pair.key_pair.key_name
  vpc_security_group_ids = [aws_security_group.app_sg.id]

  tags = {
    Name = "App-Server"
  }
}
