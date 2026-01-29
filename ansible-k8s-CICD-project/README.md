# Production-Ready DevSecOps Pipeline with Infrastructure as Code, Secrity Scanning & Ansible-Based Deployment

## Project Overview
The primary objective of this project is to establish a robust, end-to-end CI/CD pipeline that automates the process of building, testing, and deploying a Java application. By integrating a modern DevOps toolchain including Git, Jenkins, Maven, SonarQube, Docker, Trivy, Ansible, Terraform, and Amazon EKS, this project aims to achieve rapid, reliable, and secure software delivery.<br>


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
      "sudo usermod -aG docker jenkins",
      "sudo wget -O /etc/yum.repos.d/jenkins.repo https://pkg.jenkins.io/redhat-stable/jenkins.repo",
      "sudo rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io-2023.key",
      "sudo yum install jenkins -y",
      "sudo systemctl enable jenkins",
      "sudo systemctl start jenkins",
      "sudo docker run -d --name sonar -p 9000:9000 sonarqube"
      "sudo rpm -ivh https://github.com/aquasecurity/trivy/releases/download/v0.18.3/trivy_0.18.3_Linux-64bit.rpm"
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
curl --silent --location "https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_$(uname -s)_amd64.tar.gz" \ | tar xz -C /tmp
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
   f. AWS Credentials<br>
4. Restart Jenkins if prompted<br>

### Add Credentials in Jenkins
Add credentials required for Docker, GitHub, and Ansible operations<br>
1. Go to Jenkins Dashboard<br>
2. Navigate to:<br>
   Manage Jenkins → Credentials → System → Global credentials → Add Credentials<br>
   
a. DockerHub Credentials<br>
   1. Kind: usernamePassword Text<br>
   2. Username: Your Docker Hub username<br>
   3. Password: Docker Hub password or Access Token
   4. ID: dockerhub<br>
   5. Description: DockerHub credentials<br>

b. GitHub Token<br>
   1. Kind: Secret Text<br>
   2. Secret: GitHub Personal Access Token<br>
   3. ID: githubtoken<br>
   4. Description: GitHub access token<br>

c. SSH Credentials (For Ansible)<br>
   1. Kind: SSH Username with private key<br>
   2. ID: ssh<br>
   3. Username: ec2-user<br>
   4. Private Key: Paste the private key of utils (Jenkins) server<br>
   5. Description: SSH access for Ansible<br>
   
d. Add SonarQube Token in Jenkins<br>
   1. Kind: Secret Text<br>
   2. Secret: Paste SonarQube token<br>
   3. ID: sonartoken<br>
   4. Description	SonarQube token for Jenkins<br>
      
e. Add AWS Credentials in Jenkins<br>
   1. Kind: AWS Credentials<br>
   2. ID: aws-credentials<br>
   3. Access Key ID: AKIAxxxx<br>
   4. Secret Access Key: ********<br>
   5. Description: AWS access for CI/CD<br>
   
<img width="1010" height="553" alt="Screenshot 2026-01-29 202137" src="https://github.com/user-attachments/assets/322dbe27-909a-41b8-9432-2a33bad95fcf" />


This credential allows Jenkins to connect to the app server without password.<br>

<img width="1790" height="680" alt="Screenshot 2026-01-29 182952" src="https://github.com/user-attachments/assets/f815b7c7-64c3-4153-89d0-26a20f650b9d" />

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
<img width="1804" height="828" alt="Screenshot 2026-01-29 183122" src="https://github.com/user-attachments/assets/d7e8cb98-a4f6-4f3c-9d95-40f79a0b3fce" />


### Create Jenkinsfile for CI/CD Pipeline
Create a file named Jenkinsfile in the root of your GitHub repository.
#### Jenkinsfile (End-to-End CI/CD)
```
pipeline {
    agent any

    environment {
        APP_DIR     = 'ansible-k8s-CICD-project/Application'
        ANSIBLE_DIR = 'ansible-k8s-CICD-project/ansible'
        IMAGE_NAME  = 'kadivetikavya/k8s'
    }

    stages {

        stage('Checkout Code') {
            steps {
                git branch: 'main',
                    url: 'https://github.com/kadivetikavya/PROJECTS.git'
            }
        }

        stage('Build Jar') {
            steps {
                dir("${APP_DIR}") {
                    sh 'mvn clean package'
                }
            }
        }

        stage('SonarQube Scan') {
            steps {
                withCredentials([string(credentialsId: 'sonartoken', variable: 'sonartoken')]) {
                    dir("${APP_DIR}") {
                        sh '''
                        mvn sonar:sonar \
                          -Dsonar.host.url=http://35.170.52.40:9000/ \
                          -Dsonar.login=$sonartoken
                        '''
                    }
                }
            }
        }

        stage('Build Docker Image') {
            steps {
                dir("${APP_DIR}") {
                    sh "docker build -t ${IMAGE_NAME}:${BUILD_NUMBER} ."
                }
            }
        }

        stage('Docker Image Scan') {
            steps {
                sh '''
                trivy image \
                  --severity HIGH,CRITICAL \
                  --exit-code 1 \
                  --no-progress \
                  --timeout 10m \
                  ${IMAGE_NAME}:${BUILD_NUMBER}
                '''
            }
        }

        stage('Push to Docker Hub') {
            steps {
                withCredentials([usernamePassword(
                    credentialsId: 'dockerhub',
                    usernameVariable: 'DOCKER_USER',
                    passwordVariable: 'DOCKER_PASS'
                )]) {
                    sh '''
                    echo "$DOCKER_PASS" | docker login -u "$DOCKER_USER" --password-stdin
                    docker push ${IMAGE_NAME}:${BUILD_NUMBER}
                    '''
                }
            }
        }

        stage('Update K8s Manifest') {
            steps {
                withCredentials([string(credentialsId: 'githubtoken', variable: 'githubtoken')]) {
                    dir('ansible-k8s-CICD-project') {
                        sh '''
                        git config user.email "ka@gmail.com"
                        git config user.name "kavya"

                        git remote set-url origin https://${githubtoken}@github.com/kadivetikavya/PROJECTS.git
                        git pull origin main --rebase

                        sed -i "s|k8s:.*|k8s:${BUILD_NUMBER}|g" ansible/k8s_deployment.yaml

                        git add ansible/k8s_deployment.yaml
                        git commit -m "Update image tag to ${BUILD_NUMBER}" || echo "No changes to commit"
                        git push origin main
                        '''
                    }
                }
            }
        }

        stage('Debug Ansible Paths') {
            steps {
                sh '''
                pwd
                ls -R ansible-k8s-CICD-project/ansible
                '''
            }
        }

        stage('K8s Deployment using Ansible') {
            steps {
                withCredentials([
                    aws(credentialsId: 'aws-credentials', 
                        accessKeyVariable: 'AWS_ACCESS_KEY_ID',
                        secretKeyVariable: 'AWS_SECRET_ACCESS_KEY')
                ]) {
                    ansiblePlaybook(
                        playbook: 'ansible-k8s-CICD-project/ansible/ansible_k8s_deploy_playbook.yaml',
                        inventory: 'ansible-k8s-CICD-project/ansible/inventory',
                        credentialsId: 'ssh',
                        extraVars: [
                            aws_access_key: [value: env.AWS_ACCESS_KEY_ID, hidden: true],
                            aws_secret_key: [value: env.AWS_SECRET_ACCESS_KEY, hidden: true]
                        ],
                        disableHostKeyChecking: true
                    )
                }
            }
        }
    }
}


```

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
sudo vim inventory
```
Add the app server details:
```
[appserver]
appserver-publicip
```

### Test Ansible Connectivity
Verify Ansible can connect to the app server:
```
ansible -i inventory -m ping all
```
Expected result: SUCCESS✅

### Pipeline Execution and Results
Once the Jenkins pipeline is configured and triggered, it will execute each stage. The following images show a successful pipeline run.

### Jenkins Blue Ocean View
The Blue Ocean interface provides a modern, visual representation of the pipeline flow, clearly showing the status of each stage.

<img width="2136" height="691" alt="Screenshot 2026-01-28 164707" src="https://github.com/user-attachments/assets/57b5a735-4a55-4401-80c4-2ac343297170" />


### Jenkins Stage View
The classic Stage View provides a summary of recent builds and the average time taken for each stage, which is useful for identifying bottlenecks.

<img width="2130" height="790" alt="Screenshot 2026-01-28 164637" src="https://github.com/user-attachments/assets/aade3ece-0c2f-439f-88fb-8d892164e717" />


### Kubernetes Deployment with Ansible

1. Kubernetes manifests are stored in GitHub<br>
🔗 Repo: https://github.com/kadivetikavya/PROJECTS/tree/main/ansible-k8s-CICD-project
2. Ansible playbook pulls and applies manifests to deploy the application on the EKS cluster.<br>


### Accessing the Application
Check all Kubernetes resources:
```
kubectl get svc -n ansiblek8s          #namespace
```
<br>

<img width="1489" height="217" alt="Screenshot 2026-01-29 182301" src="https://github.com/user-attachments/assets/ed77d82f-24c6-4dfb-b29d-e14336b3b8ec" /> <br>

Locate the LoadBalancer service and copy the external URL.<br>


##### Example:
```
http://adf1f5bcd753f43f1842eafd0fba4069-1375844474.us-east-1.elb.amazonaws.com
```
Paste the LoadBalancer URL into your browser to access the application.

<img width="1196" height="197" alt="Screenshot 2026-01-29 182447" src="https://github.com/user-attachments/assets/a5e52342-9ade-464b-a0a5-049df988f55a" />

