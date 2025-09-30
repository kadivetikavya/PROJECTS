# Scalable Web Application with Database

## Project Overview
Build a complete web application with a database backend, monitoring, and global content delivery.

## Use Case:
E-commerce website, blog platform, or any data-driven web application requiring global accessibility and monitoring.

## AWS Services Used
<img width="900" height="397" alt="Screenshot 2025-09-30 112701" src="https://github.com/user-attachments/assets/b62b459b-38cb-47a2-94be-75c2acb49a88" />

## Architecture Diagram
<img width="1301" height="977" alt="Screenshot 2025-09-30 113417" src="https://github.com/user-attachments/assets/8c5737d3-5b20-495e-a36a-6b7d087cb93e" />

## Data Flow & Request Processing
<img width="1208" height="1020" alt="Screenshot 2025-09-30 113557" src="https://github.com/user-attachments/assets/b35dc98a-6263-4670-8559-f7cdc3910c3d" />

## Implementation Steps
### Step 1: VPC Setup
1. Please log in to your AWS Account and type VPC in the AWS console. and click on VPC service.
2. Create VPC with CIDR 10.0.0.0/16
3. Number of Availability Zones (AZs) 2:
4. Create public subnet (10.0.1.0/24) and private subnet (10.0.2.0/24) in Availability Zone 1A
5. Create public subnet (10.0.3.0/24) and private subnet (10.0.4.0/24) in Availability Zone 1B
6. Public Subnets → for EC2 web server.
7. Private Subnets → for RDS database.

<img width="865" height="331" alt="image" src="https://github.com/user-attachments/assets/c42af99e-2d6d-4806-b7bb-58986e082740" /> <br> <br>
<img width="1079" height="334" alt="image" src="https://github.com/user-attachments/assets/231480a9-e867-4288-8a3e-51ecb9079132" /> <br> 

### Step 2: Security Groups
1. Web Server SG: Allow HTTP (80), HTTPS (443), SSH (22)
<img width="1078" height="441" alt="image" src="https://github.com/user-attachments/assets/8a08fd2c-3645-4e20-87d7-e06b9fd247cb" /><br>

### Step 3: Create subnet group on RDS
1. Go to RDS Service from the AWS Management Console
2. Click Subnet groups under Network & Security.Click Create DB subnet group.
3. Give name app-subnetgroup & Select the VPC you created earlier.
4. Choose Availability Zones: us-east-1a, us-east-1b
Select Subnets:
private-sub-1a
private-sub-1b
5. Click on create the Subnet Group
<img width="1052" height="476" alt="image" src="https://github.com/user-attachments/assets/333aedc7-5cf7-42ee-852a-d2ec8b78ff63" />

### Step 4: Create RDS Database
 1. Click Create database. Choose Standard create.
 2. Select Engine - MySQL.
 3. Choose Database Templates. In our case  → Dev/Test (Multi-AZ DB instance deployment (2 instances)).
 4. Credentials Settings DB
    instance identifier: app-db.
    Master username: admin (or your choice).
    Master password: enter a strong password → confirm password.
 5. DB Instance Size - Choose instance class → e.g., db.m5.medium (if available).
 6. Storage - Default is fine (e.g., 20 GiB gp2/gp3).
    Enable storage autoscaling if you want. 
 7. Connectivity
    VPC: Select your created VPC.
    Subnet group: Select app-subnetgroup.
    Public access: No (to keep DB private).
    VPC security group: Choose/create one (allow MySQL/Postgres port, e.g. 3306 for MySQL).
 8. Additional Configurations
    Enable automated backups (default is 7 days).
    Multi-AZ deployment: enable if you need high availability.
 9. Click on Create Database.
 
### step 5: Launch EC2 Web Server
1. Go to EC2 Service
   Open AWS Console → EC2.Click Launch instance.
2. Name & Tags - Instance name: app-webserver.
3. Choose AMI - Select Amazon Linux.
4. Instance Type - Choose t3.micro for better performance.
5. Select an existing key pair or create a new one.
6. Network Settings
   VPC: Select your created VPC.
   Subnet: Choose a public subnet (e.g., public-sub-1a).
   Auto-assign public IP: Enable (so you can SSH).
   Security group: Select your created security group.
   Allow SSH (22) from your IP.
   Allow HTTP (80) from anywhere (for web server).
    Allow HTTPS (443).
7. Storage
   Default 8 GiB EBS is fine.
   Launch Instance.
   Click on Launch.
<img width="2087" height="599" alt="image" src="https://github.com/user-attachments/assets/a9e70a8f-23e2-4b5e-b7ae-f9fe42302972" />

### step 6: Install Web Server (Apache)
After instance is running:
#### 1. Connect via SSH
```
ssh -i your-key.pem ec2-user@<Public-IP>
```
#### 2. Update and install Apache 
```
sudo yum update -y
sudo yum install -y httpd php php-mysqlnd
sudo systemctl start httpd
sudo systemctl enable httpd
```
#### 3. Install Database Drivers
```
sudo yum install -y mariadb
```
#### 4. Test Web Server
```
echo "Hello from App Web Server!" > /var/www/html/index.html
```
Visit http://<EC2-Public-IP> in browser → you should see the message.
