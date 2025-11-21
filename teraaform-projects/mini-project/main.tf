provider "aws" {
    region = "us-east-1" 
}
# Step-1: Create VPC
resource "aws_vpc" "proj-vpc" {
    cidr_block = "10.81.0.0/16"
    tags = {
        Name = "proj-vpc"
    }
}

# Step-2: Create Internet Gateway
resource "aws_internet_gateway" "proj-igw" {
    vpc_id = aws_vpc.proj-vpc.id
    tags = {
        Name = "proj-igw"
    }
  
}
# Step-3: Create Route Table
resource "aws_route_table" "proj-rt" {
    vpc_id = aws_vpc.proj-vpc.id
    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.proj-igw.id
    }
    tags = {
        Name = "proj-rt"
    }
  
}
# Step-4: Create Public Subnet
resource "aws_subnet" "proj-sub" {
    vpc_id = aws_vpc.proj-vpc.id
    cidr_block = "10.81.1.0/24"
    tags = {
      Name = "proj-subnet"
    }
  
}

# Step-5: Associate Route Table with Subnet
resource "aws_route_table_association" "proj-rt-assoc" {
    subnet_id = aws_subnet.proj-sub.id
    route_table_id = aws_route_table.proj-rt.id
}
# Step-6: Create Security Group
resource "aws_security_group" "proj-sg" {
    description = "Allow SSH and HTTP"
    vpc_id      = aws_vpc.proj-vpc.id

    ingress {
        from_port   = 22
        to_port     = 22
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    ingress {
        from_port   = 80
        to_port     = 80
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    egress {
        from_port   = 0       #all ports
        to_port     = 0
        protocol    = "-1"    #all protocols
        cidr_blocks = ["0.0.0.0/0"]
    }
    tags = {
        Name = "proj-sg"
    }
}
# Step-7: create a network interface
resource "aws_network_interface" "proj-nic" {
    subnet_id       = aws_subnet.proj-sub.id
    security_groups = [aws_security_group.proj-sg.id]
    tags = {
        Name = "proj-nic"
    }
}
# Step-8: associate elastic IP with network interface
resource "aws_eip" "proj-eip"{
    network_interface = aws_network_interface.proj-nic.id
    tags = {
        Name = "proj-eip"
    }
}
# Step-9: Launch EC2 instance
resource "aws_instance" "proj-ec2" {
    ami                    = "ami-0fa3fe0fa7920f68e" # Amazon Linux 2 AMI
    instance_type          = "t2.micro"
    user_data = file("userdata.sh")
    network_interface {
        network_interface_id = aws_network_interface.proj-nic.id
        device_index         = 0
    }
    tags = {
        Name = "proj-ec2"
    }
}