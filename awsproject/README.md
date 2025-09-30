# Scalable Web Application with Database

## Project Overview
Build a complete web application with a database backend, monitoring, and global content delivery.

## Use Case:
E-commerce website, blog platform, or any data-driven web application requiring global accessibility and monitoring.

## AWS Services Used
<img width="917" height="476" alt="image" src="https://github.com/user-attachments/assets/b767c115-d91a-4450-9e6f-1d8904ea382a" />

<img width="737" height="589" alt="image" src="https://github.com/user-attachments/assets/74d26d70-ec15-4ce1-8e9f-d1f19647c09e" />

<img width="1300" height="1158" alt="image" src="https://github.com/user-attachments/assets/783143ca-fc25-47c1-95b5-a98e00b664a7" />

## Implementation Steps
### Step 1: VPC Setup
1. Create VPC with CIDR 10.0.0.0/16
2. Number of Availability Zones (AZs) 2:
3. Create public subnet (10.0.1.0/24) and private subnet (10.0.2.0/24) in Availability Zone 1A
4. Create public subnet (10.0.3.0/24) and private subnet (10.0.4.0/24) in Availability Zone 1B
5. Public Subnets → for EC2 web server.
6. Private Subnets → for RDS database.
<img width="1079" height="334" alt="image" src="https://github.com/user-attachments/assets/231480a9-e867-4288-8a3e-51ecb9079132" />

<img width="2033" height="858" alt="image" src="https://github.com/user-attachments/assets/baea12e2-f5d3-4cb5-93fd-b57b5e3802a4" />

<img width="2039" height="873" alt="image" src="https://github.com/user-attachments/assets/f3a132be-5244-47d8-85e4-2c82ad8d150c" />

<img width="2057" height="982" alt="image" src="https://github.com/user-attachments/assets/8bd950f1-bf4d-48c5-b504-ad86ac51f5e5" />

<img width="2014" height="968" alt="Screenshot 2025-09-30 120227" src="https://github.com/user-attachments/assets/c2051f47-3073-4194-ab42-93678024d2aa" />



Configure Internet Gateway for public subnet and Route Table rules.
Add Security Groups:
Allow HTTP/HTTPS (80/443) and SSH (22) to EC2.


