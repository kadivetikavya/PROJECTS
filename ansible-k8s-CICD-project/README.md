# Production-Ready DevSecOps Pipeline with Infrastructure as Code, Secrity Scanning & Ansible-Based Deployment

### Project Overview
The primary objective of this project is to establish a robust, end-to-end CI/CD pipeline that automates the process of building, testing, and deploying a Java application. By integrating a modern DevOps toolchain including Git, Jenkins, Maven, SonarQube, Docker, Trivy, Ansible, Terraform, and Amazon EKS, this project aims to achieve rapid, reliable, and secure software delivery.<br>

#### This project aims to achieve the following goals:
1. Infrastructure as Code (IaC): Use Terraform to provision and manage the entire AWS infrastructure, ensuring consistency, repeatability, and version control of the environment. This includes all networking components and server instances.<br>
2. Version Control: Maintain both application source code and infrastructure code (Terraform) in Git repositories to enable collaboration, tracking, and auditability.<br>
3. Continuous Integration (CI): Automate the build, test, and code analysis processes using a Jenkins pipeline triggered by code commits. This ensures early detection of integration issues and maintains high code quality.<br>
4. Static Code Analysis: Integrate SonarQube to perform continuous inspection of code quality, identifying bugs, vulnerabilities, and code smells before they reach production.<br>
5. Containerization: Package the application and its dependencies into a standardized Docker container, creating a portable and consistent runtime environment.<br>
6. Container Security: Implement vulnerability scanning for Docker images using Trivy to identify and mitigate security risks before deployment.<br>
7. Continuous Deployment (CD): Automate the deployment of the containerized application to a Kubernetes cluster using Ansible, enabling a seamless and controlled rollout process.<br>


## Architecture and Pipeline Flow
<img width="1821" height="700" alt="2 drawio (1)" src="https://github.com/user-attachments/assets/980684c6-bd08-4379-96ce-bc9314bf1979" />

## Infrastructure Architecture
The AWS infrastructure is designed with a custom VPC to host the CI/CD tools and the application
runtime. It consists of two primary server types: <br>
1. UTIL Server: An EC2 instance that hosts the core CI/CD components: Git, Jenkins, Ansible,
Docker, Maven, SonarQube, and Trivy. <br>
2. App Server (EKS Cluster): An Amazon Elastic Kubernetes Service (EKS) cluster that serves as
the runtime environment for the deployed application. <br>

<img width="1141" height="631" alt="Untitled Diagram drawio" src="https://github.com/user-attachments/assets/31bef70b-29f8-4c0f-a11e-c48d815b8d58" />

### The CI/CD Workflow Explained
1. Developers push code to GitHub. <br>
2. Terraform provisions the necessary infrastructure. <br>
3. Jenkins pulls code from GitHub, builds it with Maven, runs static code analysis with SonarQube, builds a 
Docker image, and pushes it to DockerHub. <br>
4. Trivy scans the Docker image for vulnerabilities. <br>
5. Jenkins updates the deployment manifests in the GitHub repository for Ansible. <br>
6. Ansible deploys the application to the Kubernetes cluster on EKS. <br>

### Installations and Setting up: 
a. Github url:  https://github.com/kadivetikavya/PROJECTS/tree/main/ansible-k8s-CICD-project<br>
b. Terraform installation on windows: <br>
https://releases.hashicorp.com/terraform/1.8.5/terraform_1.8.5_windows_386.zip<br>
   1. Download the Terraform ZIP file from the link above. <br>
   2. Extract the ZIP file to a directory (e.g., C:\terraform). <br>
   3.  Add the Terraform directory to the system's PATH environment variable <br>

### AWS CLI Configuration on Windows 
Install AWS CLI <br>
1. Download from:<br>
👉 https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html
2. Run installer → Next → Finish<br>
3. Verify: 
```
aws --version
```
Configure AWS CLI
```
aws configure
```
This will prompt for AWS Access Key ID, Secret Access Key, Default Region, and Default Output Format.<br>

### Generate SSH Key Pair (Windows)
1. Generate ssh-keygen in gitbash / visual studio code
```
ssh-keygen -t rsa
cd ~/.ssh
ls
cat id_rsa.pub
```
2. Copy public key (id_rsa.pub)<br>
3. Use it in Terraform key pair <br>

### Infrastructure Provisioning using Terraform
Using Terraform, we create:<br>
1. VPC<br>
2. Public Subnets<br>
3. Internet Gateway & Route Tables<br>
4. Security Groups<br>
5. EC2 Instances<br>
   a. Jenkins (Utils) Server<br>
   b. Application Server<br>
6. Key Pair (using public key)<br>
All resources are provisioned in an automated and repeatable manner.<br>

#### Terraform Files Structure

terraform/ <br>
├── main.tf <br>
└── outputs.tf<br>

#### main.tf:
```
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

```
<br>

#### outputs.tf
```
output "jenkins_public_ip" {
  value       = aws_instance.jenkins.public_ip
  description = "Public IP of Jenkins Server"
}

output "app_public_ip" {
  value       = aws_instance.app.public_ip
  description = "Public IP of App Server"
}
```

<br>

### You Are Good To Go
1. Initialize Terraform:
```
terraform init
```
2. Plan the infrastructure changes:
``` 
terraform plan
```
3. Apply the changes to deploy the infrastructure:
```
terraform apply 
```

### Access the Jenkins & SonarQube web interface
a. Jenkins UI<br>
Open your browser and navigate to:
```
http://<your-jenkins-server-ip>:8080
```
b. SonarQube UI<br>
Open your browser and navigate to:
```
http://<your-jenkins-server-ip>:9000
```
c. Default SonarQube Credentials
```
Username: admin
Password: admin
```   
d. First-Time SonarQube Login<br>
   1. Log in using the default credentials<br>
   2. Change the default password when prompted<br>
e. Create Sonar Token for Jenkins<br>
1. Go to SonarQube Dashboard<br>
2. Navigate to:<br>
   Administration → My Account → Security<br>
3. Click Generate Token<br>
4. Copy and save the token (used in Jenkins pipeline)<br>

### Generate GitHub Token for Jenkins
1. Go to GitHub → Settings<br>
2. Select Developer settings<br>
3. Click Personal access tokens<br>
4. Generate a new token with required scopes:<br>
   a. repo<br>
   b. workflow<br>
5. Copy and save the token (used in Jenkins credentials)<br>

### Connect to Jenkins Server (Without PEM Key)

Since the key pair was created using your local SSH key, connect using your private key.
```
ssh -i ~/.ssh/id_rsa ec2-user@<jenkins-server-ip>
```
Rename Jenkins Server Hostname
```
sudo hostnamectl set-hostname utils-server
```
Switch to Root User
```
sudo su -
```
Get Jenkins Initial Admin Password
```
cat /var/lib/jenkins/secrets/initialAdminPassword
```
Use this password to unlock Jenkins on first login.


### Connect to App Server
```
ssh -i ~/.ssh/id_rsa ec2-user@<app-server-ip>
# Rename App Server Hostname
sudo hostnamectl set-hostname app-server
# Switch to Root User
sudo su -
```

### Configure AWS CLI on App Server
Configure AWS CLI to allow interaction with AWS services:
```
aws configure
```
This will prompt for AWS Access Key ID, Secret Access Key, Default Region, and Default Output 
Format.<br>

### Install kubectl and eksctl on App Server
```
#Install kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl.sha256"
echo "$(cat kubectl.sha256)  kubectl" | sha256sum --check
install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
kubectl version --client

# Install eksctl
curl --silent --location "https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_$(uname -s)_amd64.tar.gz" \ 
| tar xz -C /tmp
sudo mv /tmp/eksctl /usr/local/bin
eksctl version
```

### Create EKS Cluster 
Create an EKS cluster using eksctl:  
```
eksctl create cluster --name myappcluster --nodegroup-name myng --node-type t3.micro --nodes 5 --managed
```
Verify cluster:
```
eksctl get cluster
kubectl get nodes
```
### Install Required Jenkins Plugins
Install the required plugins in Jenkins to support CI/CD automation. <br>
1. Go to Jenkins Dashboard<br>
2. Navigate to:<br>
   a. Manage Jenkins → Manage Plugins → Available<br>
3. Search and install the following plugins:<br>
   a. Docker<br>
   b. Pipeline<br>
   c. Pipeline Stage View<br>
   d. Blue Ocean<br>
   e. Ansible<br>
4. Restart Jenkins if prompted<br>


### Add Credentials in Jenkins
Add credentials required for Docker, GitHub, and Ansible operations<br>
1. Go to Jenkins Dashboard<br>
2. Navigate to:<br>
   Manage Jenkins → Credentials → System → Global credentials → Add Credentials<br>
a. DockerHub Credentials<br>
   Kind: Secret Text<br>
   Secret: DockerHub password / token<br>
   ID: dockerhub<br>
   Description: DockerHub credentials<br>

b. GitHub Token<br>
   Kind: Secret Text<br>
   Secret: GitHub Personal Access Token<br>
   ID: githubtoken<br>
   Description: GitHub access token<br>

c. SSH Credentials (For Ansible)
   Kind: SSH Username with private key<br>
   ID: ssh<br>
   Username: ec2-user<br>
   Private Key: Paste the private key of utils (Jenkins) server<br>
   Description: SSH access for Ansible<br>
This credential allows Jenkins to connect to the app server without password.<br>

### Add SSH Credential ID for Ansible 
Add Ansible Installation in Jenkins<br>
1. Go to Jenkins Dashboard<br>
2. Navigate to:<br>
   Manage Jenkins → Tools<br>
3. Scroll to Ansible installations<br>
4. Click Add Ansible<br>
5. Configure:<br>
   Name: ansible<br>
   Path to ansible executables: /usr/bin/<br>
6. Save the configuration<br>
This allows Jenkins pipelines to use Ansible during deployment.<br>

### Create Jenkinsfile for CI/CD Pipeline
Create a file named Jenkinsfile in the root of your GitHub repository.
#### Jenkinsfile (End-to-End CI/CD)
```
pipeline {
    agent any

    stages {

        stage('Checkout Code') {
            steps {
                echo 'Checking out source code'
                git branch: 'main',
                    url: 'https://github.com/kadivetikavya/PROJECTS.git'
            }
        }

        stage('Build Jar') {
            steps {
                echo 'Running Maven build'
                sh '''
                  cd Application
                  mvn clean package
                '''
            }
        }

        stage('Sonar Scan') {
            steps {
                echo 'Running SonarQube scan'
                withCredentials([string(credentialsId: 'sonartoken', variable: 'SONAR_TOKEN')]) {
                    sh '''
                      cd Application
                      mvn sonar:sonar \
                        -Dsonar.host.url=http://<sonarqube-server-ip>:9000 \
                        -Dsonar.login=${SONAR_TOKEN}
                    '''
                }
            }
        }

        stage('Build Docker Image') {
            steps {
                echo 'Building Docker Image'
                sh '''
                  cd Application
                  docker build -t kadivetikavya/k8s:${BUILD_NUMBER} .
                '''
            }
        }

        stage('Docker Image Scan') {
            steps {
                sh '''
                  trivy image kadivetikavya/k8s:${BUILD_NUMBER}
                '''
            }
        }

        stage('Push Image to DockerHub') {
            steps {
                withCredentials([string(credentialsId: 'dockerhub', variable: 'DOCKER_PASS')]) {
                    sh '''
                      docker login -u kadivetikavya -p ${DOCKER_PASS}
                      docker push kadivetikavya/k8s:${BUILD_NUMBER}
                    '''
                }
                echo 'Pushed to Docker Hub'
            }
        }

        stage('Update Kubernetes Deployment Manifest File') {
            environment {
                GIT_REPO_NAME = "PROJECTS"
                GIT_USER_NAME = "kadivetikavya"
            }
            steps {
                withCredentials([string(credentialsId: 'githubtoken', variable: 'GITHUB_TOKEN')]) {
                    sh '''
                      git config user.email "ka@gmail.com"
                      git config user.name "kadivetikavya"

                      sed -i "s|image:.*|image: kadivetikavya/k8s:${BUILD_NUMBER}|g" \
                      ansible-k8s-CICD-project/ansible/k8s-deployment.yaml

                      git add .
                      git commit -m "Update deployment image tag to ${BUILD_NUMBER}"
                      git push https://${GITHUB_TOKEN}@github.com/${GIT_USER_NAME}/${GIT_REPO_NAME}.git main
                    '''
                }
            }
        }

        stage('K8s Deployment using Ansible') {
            steps {
                ansiblePlaybook(
                    credentialsId: 'ssh',
                    disableHostKeyChecking: true,
                    installation: 'ansible',
                    inventory: '/etc/ansible/hosts',
                    playbook: 'ansible/ansible_k8s_deploy_playbook.yaml'
                )
            }
        }
    }
}

```
<br>

###  Continuous Deployment with Ansible
#### Generate SSH Key on Jenkins (Utils) Server
Login as ec2-user on the Jenkins server and generate SSH keys.
```
sudo su - ec2-user
pwd
# You should be in /home/ec2-user

ssh-keygen
ls -la
cd ~/.ssh
cat id_rsa.pub
```
#### Copy the public key (id_rsa.pub)

#### Paste Public Key on App Server
Login to the app server and configure passwordless SSH.
```
sudo su - ec2-user
ls -la
cd ~/.ssh
vim authorized_keys
```
Paste the copied public key and save the file.<br>

### Verify Passwordless SSH
From the Jenkins (utils) server:
```
ssh ec2-user@appserver-publicip
```
Passwordless SSH authentication should work
Exit the app server:
```
exit
```
### Configure Ansible Inventory
Navigate to Ansible configuration directory:
```
cd /etc/ansible
sudo vim hosts
```
Add the app server details:
```
[appserver]
appserver-publicip
```

### Test Ansible Connectivity
Verify Ansible can connect to the app server:
```
ansible -i hosts -m ping all
```
Expected result: SUCCESS✅

### Kubernetes Deployment with Ansible

1. Kubernetes manifests are stored in GitHub<br>
🔗 Repo: https://github.com/kadivetikavya/PROJECTS/tree/main/ansible-k8s-CICD-project
2. Ansible playbook pulls and applies manifests to deploy the application on the EKS cluster.<br>


### Accessing the Application
Check all Kubernetes resources:
```
kubectl get all
```
Locate the LoadBalancer service and copy the external URL.<br>
Example:
```
a2a5e5f083b26430fadf920fe4f2a782-1459326598.us-east-1.elb.amazonaws.com
```
Paste the LoadBalancer URL into your browser to access the application 🎉




