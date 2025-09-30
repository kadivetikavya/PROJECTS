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

<img width="865" height="331" alt="image" src="https://github.com/user-attachments/assets/c42af99e-2d6d-4806-b7bb-58986e082740" /> <br>
<img width="1079" height="334" alt="image" src="https://github.com/user-attachments/assets/231480a9-e867-4288-8a3e-51ecb9079132" /> <br>
<img width="1079" height="334" alt="image" src="https://github.com/user-attachments/assets/231480a9-e867-4288-8a3e-51ecb9079132" /> <br>

<img width="2033" height="858" alt="image" src="https://github.com/user-attachments/assets/baea12e2-f5d3-4cb5-93fd-b57b5e3802a4" /> <br>

<img width="2039" height="873" alt="image" src="https://github.com/user-attachments/assets/f3a132be-5244-47d8-85e4-2c82ad8d150c" /> <br>

<img width="2057" height="982" alt="image" src="https://github.com/user-attachments/assets/8bd950f1-bf4d-48c5-b504-ad86ac51f5e5" /> <br>

<img width="2014" height="968" alt="Screenshot 2025-09-30 120227" src="https://github.com/user-attachments/assets/c2051f47-3073-4194-ab42-93678024d2aa" />



Configure Internet Gateway for public subnet and Route Table rules.
Add Security Groups:
Allow HTTP/HTTPS (80/443) and SSH (22) to EC2.
