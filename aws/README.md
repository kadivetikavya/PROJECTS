# Scalable Web Application with Database

## Project Overview
Build a complete web application with a database backend, monitoring, and global content delivery.

## AWS Services Used
<img width="900" height="397" alt="Screenshot 2025-09-30 112701" src="https://github.com/user-attachments/assets/b62b459b-38cb-47a2-94be-75c2acb49a88" />

## Architecture Diagram
<img width="1301" height="977" alt="Screenshot 2025-09-30 113417" src="https://github.com/user-attachments/assets/8c5737d3-5b20-495e-a36a-6b7d087cb93e" />

## Data Flow & Request Processing
<img width="1208" height="1020" alt="Screenshot 2025-09-30 113557" src="https://github.com/user-attachments/assets/b35dc98a-6263-4670-8559-f7cdc3910c3d" />

## Implementation Steps
### Step 1: VPC Setup
1. Please log in to your AWS Account and type VPC in the AWS console. and click on VPC service.
2. Select "VPC and more"
3. Create VPC with CIDR 10.0.0.0/16
4. Number of Availability Zones (AZs) → 2:
5. Create public subnet (10.0.1.0/24) and private subnet (10.0.2.0/24) in Availability Zone 1a
6. Create public subnet (10.0.3.0/24) and private subnet (10.0.4.0/24) in Availability Zone 1b
7. Configure NAT Gateways
   NAT gateways → 1 per AZ
8. Configure VPC Endpoints
   VPC Endpoints → None
9. Click on Create VPC. 
<img width="2135" height="481" alt="Screenshot 2025-09-30 124024" src="https://github.com/user-attachments/assets/58f8100b-84ce-4c77-a74a-077b759b7a5a" /> <br>

### Step 2: Security Groups
1. Web Server SG: Allow HTTP (80), HTTPS (443), SSH (22) <br>

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
 9. Click on Create Database. <br>

 <img width="2122" height="564" alt="image" src="https://github.com/user-attachments/assets/c5cfe30a-1a53-43a8-b6ff-f047632272ea" />

### Step 5: Launch EC2 Web Server
1. Go to EC2 Service
   Open AWS Console → EC2.Click Launch instance.
2. Name & Tags - Instance name: app-webserver.
3. Choose AMI - Select ubuntu.
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

### Step 6: Install Web Server (Apache)
After instance is running:
#### 1. Connect via SSH
```
ssh -i your-key.pem ec2-user@<Public-IP>
```
#### 2. Install apache & mysql-serverr 
```
sudo apt update -y
sudo apt install -y apache2
sudo systemctl start apache2
sudo systemctl enable apache2
sudo apt install -y php8.1 libapache2-mod-php8.1 php8.1-mysql
sudo a2enmod php8.1
sudo apt install -y mysql-server
```
#### 3. Start service
```
sudo systemctl enable --now mysql
```
#### 4. Run secure setup
```
sudo mysql_secure_installation
```
#### 5. Check status
```
systemctl status mysql
```
#### 6. Test MySQL client
```
mysql --version
```
#### 7. connect to RDS
```
mysql -h <RDS-ENDPOINT> -u <USERNAME> -p
it is looks like this 
mysql -h app-db.citw4gmew45o.us-east-1.rds.amazonaws.com -u admin -p
then add your password
```
#### 8. Successful login
```
after successful login it looks like this
Welcome to the MySQL monitor.  Commands end with ; or \g.
mysql>
```
#### 9. List databases
```
SHOW DATABASES;
```
#### 10. Create and Use a Database
```
CREATE DATABASE appdb;
USE appdb;
CREATE TABLE users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(50),
    email VARCHAR(100)
);
SHOW DATABASES;
SHOW TABLES; 
```
#### 11. Insert data
```
INSERT INTO users (name, email) VALUES ('Kavya', 'kavya@example.com');
```

#### 12. Query data
```
SELECT * FROM users;
```
### Step 7: Create PHP file
#### 1. Create PHP file userdata
```
sudo nano /var/www/html/users.php
```
#### 2. Paste this code
```
<?php
$host = "your-rds-endpoint";  // e.g., app-db.xxxxxx.us-east-1.rds.amazonaws.com
$user = "admin";
$pass = "yourpassword"; // e.g.,your password
$db   = "appdb";

// Connect to RDS
$conn = mysqli_connect($host, $user, $pass, $db);

if (!$conn) {
    die("Connection failed: " . mysqli_connect_error());
}

// Fetch users
$result = mysqli_query($conn, "SELECT * FROM users");

echo "<h2>Users Table:</h2><ul>";
while($row = mysqli_fetch_assoc($result)) {
    echo "<li>" . $row['id'] . " - " . $row['name'] . " - " . $row['email'] . "</li>";
}
echo "</ul>";

mysqli_close($conn);
?>

```
#### 3. Change permissions
```
sudo chown www-data:www-data /var/www/html/users.php
sudo chmod 644 /var/www/html/users.php
```
#### 4. Test PHP Execution
```
sudo nano /var/www/html/info.php
```
#### 5. Paste
```
<?php phpinfo(); ?>
```
#### 6. Visit in browser
```
http://<EC2-Public-IP>/info.php
```
<img width="1793" height="1329" alt="image" src="https://github.com/user-attachments/assets/ea6b39fd-2d2e-47a1-be62-6af2242a0a8c" /> <br>

#### 7. Test in browser
```
http://<EC2-Public-IP>/users.php
```
<img width="929" height="434" alt="image" src="https://github.com/user-attachments/assets/7858b192-72ab-4694-b8ee-41bbfdaa70fe" /> <br>

### Step 8: S3 and Route53
#### 1. Create S3 Bucket for Static Assets
1. Go to AWS Console → S3 → Create bucket
2. Bucket name: app-project-buc (must be globally unique)
3. Region: Choose the same region as your EC2
4. Public access settings:
   Uncheck Block all public access
5. Acknowledge warning
6. Click Create bucket

<img width="1044" height="270" alt="image" src="https://github.com/user-attachments/assets/aa01c8cc-d1ea-4389-9ed8-df2efe0cd43f" />

#### 2. Upload Static Assets
1. Go to your bucket → Upload → add files (images, html, CSS, JS)
2. Here i uploaded index.html, error.html files

<img width="1060" height="376" alt="image" src="https://github.com/user-attachments/assets/63294c7b-fd36-4f7e-a984-2dc5d1de2d04" />

#### 3. Configure Bucket Policy for Public Read
1. Go to Permissions → Bucket policy
2. Paste this policy (replace app-static-assets with your bucket name):
```
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "PublicRead",
            "Effect": "Allow",
            "Principal": "*",
            "Action": "s3:GetObject",
            "Resource": "arn:aws:s3:::app-project-buc/*"
        }
    ]
}
```
4. Save policy → now all files in the bucket are publicly accessible.
5. Allow all checklist - Edit access control list (ACL)
6. Test:
   https://app-project-buc.s3.amazonaws.com/index.html

<img width="802" height="427" alt="image" src="https://github.com/user-attachments/assets/8cd207ac-c58f-4f49-b9b5-972c7bc1c9ea" />

#### 4. Register Domain / Configure Hosted Zone in Route53
1. Register new domain
2. Go to Route53 → Domains → Register domain
3. Enter domain name → follow steps to purchase
(or)
1. Use existing domain
2. I have a domain in godaddy.com
3. Go to Route53 → Hosted zones → Create hosted zone
4. Domain name: example.com
5. Type: Public Hosted Zone
6. Click Create hosted zone <br>

<img width="2099" height="916" alt="image" src="https://github.com/user-attachments/assets/bcf273d6-050b-48f6-bcd2-2a08f9ce1e72" />
#### 5. change Nameservers in godaddy
<img width="818" height="581" alt="image" src="https://github.com/user-attachments/assets/df9708b9-1729-4cd9-82e5-2dcafe546791" />
<br>
<img width="797" height="604" alt="image" src="https://github.com/user-attachments/assets/b673cfdd-9038-4ba3-bcba-9da306620857" />

#### 6. Create A Record to Point Domain to EC2 Public IP
1. Go to Hosted zone → Create record
2. Record type: A – IPv4 address
3. Name: www (so your domain is www.example.com) or leave blank for root domain
4. Value: Enter your EC2 public IP
5. Routing policy: Simple
6. Save record <br>

<img width="1081" height="521" alt="image" src="https://github.com/user-attachments/assets/de2b29bd-bd80-4621-9163-937c9e849209" />
<img width="699" height="247" alt="image" src="https://github.com/user-attachments/assets/00759609-028c-42ec-b0b9-2345f2f1ba0e" />

### Step 9:Monitoring Setup
#### 1. Set Up SNS Notifications
1. Go to SNS → Topics → Create topic
2. Type: Standard
3. Name: CriticalAlerts
4. Create subscription:
   Protocol: Email
   Endpoint: your email address
5. Subscribe → Confirm email link
6. In CloudWatch alarm → Select SNS topic as action <br>

<img width="1072" height="418" alt="image" src="https://github.com/user-attachments/assets/b806fe67-110e-495e-a23f-6426174c5325" />
#### 2. Create CloudWatch Alarms
1. Go to CloudWatch → Alarms → Create Alarm
2. Select metric:
   EC2 → Per-Instance Metrics → CPUUtilization
   EC2 → MemoryUtilization (requires CloudWatch Agent)
   EC2 → DiskSpaceUtilization
3. Set threshold:
Example: CPU > 80% for 5 minutes
4. Configure actions:
   Send notification via SNS (next step)
5. Name and create the alarm <br>

<img width="2124" height="341" alt="image" src="https://github.com/user-attachments/assets/a25297b2-0c8a-49b5-be8a-aafd898f3a12" /> <br>

<img width="988" height="437" alt="image" src="https://github.com/user-attachments/assets/88ac55aa-02ac-4461-861e-e0b9a69a027f" />

   
