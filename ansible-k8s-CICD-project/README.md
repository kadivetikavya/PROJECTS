# Production-Ready DevSecOps Pipeline with Infrastructure as Code, Secrity Scanning & Ansible-Based Deployment

### Project Overview
The primary objective of this project is to establish a robust, end-to-end CI/CD pipeline that automates the process of building, testing, and deploying a Java application. By integrating a modern DevOps toolchain including Git, Jenkins, Maven, SonarQube, Docker, Trivy, Ansible, Terraform, and Amazon EKS, this project aims to achieve rapid, reliable, and secure software delivery.<br>

### This project aims to achieve the following goals:
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
Steps: 
a. Install AWS CLI if not already installed: <br>
   1. Download the installer from AWS CLI Installer.<br> 
   2. Run the installer and follow the on-screen instructions. <br?
b. Configure AWS CLI: 
```
aws configure
```
This will prompt for AWS Access Key ID, Secret Access Key, Default Region, and Default Output Format.<br?

### Generate keypair in terminal
1. Generate ssh-keygen in terminal(gitbash/vs code)
```
ssh-keygen -t rsa
cd ~     #it will take you to your PC home directory
cd .ssh/
ll
cat id_rsa.pub
```
2. copy the public key value and paste in further steps

### Infrastructure Provisioning with Terraform
Here we are going create main.tf file to provision a VPC, subnets, security groups, EC2 instances(Jenkins and app
server ),and other necessary AWS resources.

main.tf:
```
provider "aws" {
  profile = "default"
  region  = "us-east-1"
}

#KEY PAIR 
resource "aws_key_pair" "key_pair" {
  key_name   = "MyKey"
  public_key = "Here paste our public key which is already we copy"
}

#VPC 
resource "aws_vpc" "prod" {
  cidr_block           = "172.20.0.0/16"
  enable_dns_hostnames = true

  tags = { Name = "prod" }
}

#SUBNET
resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.prod.id
  cidr_block              = "172.20.10.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true

  tags = { Name = "public-subnet" }
}

#INTERNET GATEWAY 
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.prod.id

  tags = { Name = "prod-igw" }
}

#ROUTE TABLE
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.prod.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = { Name = "public-route-table" }
}

#ROUTE TABLE ASSOCIATION
resource "aws_route_table_association" "public_rt_assoc" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_rt.id
}

#SECURITY GROUP - JENKINS
resource "aws_security_group" "jenkins_sg" {
  name        = "jenkins-sg"
  vpc_id      = aws_vpc.prod.id
  description = "SG for Jenkins Server"

  ingress {
    description = "Jenkins HTTP"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Ping"
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
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
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "jenkins-sg" }
}

#SECURITY GROUP - MyApp 
resource "aws_security_group" "myapp_sg" {
  name        = "myapp-sg"
  vpc_id      = aws_vpc.prod.id
  description = "MyApp SG"

  ingress {
    description = "MyApp Port"
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

  ingress {
    description = "All Inbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "myapp-sg" }
}

#JENKINS INSTANCE
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
      "sudo yum install wget git maven ansible docker -y",
      "sudo wget -O /etc/yum.repos.d/jenkins.repo https://pkg.jenkins.io/redhat-stable/jenkins.repo",
      "sudo rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io-2023.key",
      "sudo yum install jenkins -y",
      "sudo systemctl enable jenkins && sudo systemctl start jenkins",
      "sudo systemctl enable docker && sudo systemctl start docker",
      "sudo usermod -aG docker ec2-user",
      "sudo usermod -aG docker jenkins",
      "sudo chmod 666 /var/run/docker.sock",
      "sudo docker run -d --name sonar -p 9000:9000 sonarqube",
      "sudo rpm -ivh https://github.com/aquasecurity/trivy/releases/download/v0.18.3/trivy_0.18.3_Linux-64bit.rpm"
    ]
  }

  tags = { Name = "Jenkins-From-Terraform" }
}

#MyApp INSTANCE
resource "aws_instance" "app" {
  ami                    = "ami-0fa3fe0fa7920f68e"
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.public_subnet.id
  key_name               = aws_key_pair.key_pair.key_name
  vpc_security_group_ids = [aws_security_group.myapp_sg.id]

  tags = { Name = "App-From-Terraform" }
}
```

outputs.tf
```
output "public_ip_jenkins" {
  description = "Public IP of the Jenkins EC2 instance"
  value       = aws_instance.jenkins.public_ip
}

output "public_ip_app" {
  description = "Public IP of the MyApp EC2 instance"
  value       = aws_instance.app.public_ip
}
```

<br>

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
4. Access the Jenkins & SonarQube web interface:<br>
a. Open a web browser and go to http://<your-jenkins-server-ip>:8080 for jenkins server<br>
b. Open a web browser and go to http://<your-jenkins-server-ip>:9000 for SonarQube server<br>
c. The default login credentials are: <br>
   1. Username: admin <br>
   2. Password: admin <br>
d. Log in to SonarQube using the default credentials. <br>
   1. Change the default password<br>
e. Create Sonar token for Jenkins: <br>
   1. Sonar Dashboard -> Administration -> MyAccount -> Security -> Create token  <br>
5. Generate GitHub Token for Jenkins to access your GIT repositories: <br>
   1. Go to GitHub > Settings > Developer settings > Personal access tokens.<br>
   2. Generate a new token with the necessary scopes<br>
      
### Let's connect to jenkins servers
we don't have any pem key right now so using our private key in terminal(gitbash) <br>
```
ssh -i ~/.ssh/id_rsa ec2-user@jenkins-server-ip
sudo hostnamectl set-hostname utils-server     # to rename our server
sudo su -
cat var/jenkins_home/secrets/initialAdminPassword   # for jenkins server password
```

### connecting to app server
```
ssh-i ~/.ssh/id_rsa ec2-user@app-server-ip
sudo hostnamectl set-hostname app-server
sudo su -
```
### Configure AWS CLI in app server 
Configure AWS CLI to interact with AWS services: 
```
aws configure
```
a. This will prompt for AWS Access Key ID, Secret Access Key, Default Region, and Default Output 
Format.

### Kubectl and EKSCTL installation in app server
```
#Install kubectl and eksctl to manage kubernetes cluster:
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

### Install Required Jenkins Plugins 
Install required plugins in Jenkins:  <br>
1. Go to Jenkins Dashboard > Manage Jenkins > Manage Plugins > Available. <br>
2. Install the Docker plugin, Pipeline stage view, blue ocean, ansible plugin..etc <br>

### Add credentials 
Add credentials in Jenkins: <br>
1. Go to Jenkins Dashboard > Manage Jenkins > Credentials > System > Global credentials > Add credentials <br>
2. kind > secret text > secret - password of dockerhub > ID - give any name(eg.,dockerhub) <br>
3. kind > secret text > secret - github token > ID - give any name(eg.,githubtocken) <br>
4. kind > ssh username with private key > ID - ssh  > user name - ec2-user > private key - paste private of utils server(ansible installed in utils server only) > create <br>

### Add ssh credentialId for ansible 
Add ansible installations<br>
1. Go to Jenkins Dashboard > Manage Jenkins > Tools > Ansible installation <br>
2. Name - ansible > path - /usr/bin/ <br>


### Create Jenkinsfile for CI/CD Pipeline 
Create a Jenkinsfile in your repository to define the CI/CD pipeline: >
```
pipeline {
    agent any

    stages {

        stage('Checkout Code') {
            steps {
                echo 'Checking out source code'
                git branch: 'main', url: 'https://github.com/kadivetikavya/PROJECTS/tree/main/ansible-k8s-CICD-project'
            }
        }

        stage('Build Jar') {
            steps {
                echo 'Running Maven build'
                sh 'cd Application && mvn clean package'
            }
        }

        stage('Sonar Scan') {
            steps {
                echo 'Running SonarQube scan'
                sh '''
                    cd Application
                    mvn sonar:sonar \
                      -Dsonar.host.url=http://SonarQubeSerever-publicIp:9000 \
                      -Dsonar.login=squ_857bc378b399cc95305af238a1c3f0e10e243415     //generated sonar token
                '''
            }
        }

        stage('Build Docker Image') {
            steps {
                script {
                    echo 'Building Docker Image'
                    sh 'cd Application && docker build -t kadivetikavya/k8s:${BUILD_NUMBER} .'
                }
            }
        }

        stage('Docker Image Scan') {
            steps {
                sh 'trivy image kadivetikavya/k8s:${BUILD_NUMBER}'
            }
        }

        stage('Push Image to DockerHub') {
            steps {
                script {
                    withCredentials([string(credentialsId: 'dockerhub', variable: 'dockerhub')]) {
                         sh 'docker login -u kadivetikavya -p ${dockerhub}' 
                    } 
                    // Push the Docker image to Docker Hub 
                    sh 'docker push kadivetikavya/k8s:${BUILD_NUMBER}' 
                    echo 'Pushed to Docker Hub' 
                }
            }
        }

        stage('Update Kubernetes Deployment Manifest File') {
            environment {
                GIT_REPO_NAME = "PROJECTS"
                GIT_USER_NAME = "kadivetikavya"
            }
            steps {
                withCredentials([string(credentialsId: 'githubtocken', variable: 'githubtocken')]) {
                    sh '''
                        git config user.email "ka@gmail.com"
                        git config user.name "kadivetikavya"

                        sed -i "s|k8s:.*|k8s:${BUILD_NUMBER}|g" ansible-k8s-CICD-project/ansible/k8s-deployment.yaml

                        git add .
                        git commit -m "Update deployment image tag to version ${BUILD_NUMBER}"
                        git push https://${githubtocken}@github.com/${GIT_USER_NAME}/${GIT_REPO_NAME} HEAD:main
                    '''
                }
            }
        }

        stage('K8s Deployment using Ansible') {
            steps {
                script {
                    ansiblePlaybook(
                        credentialsId: 'ssh',
                        disableHostKeyChecking: true,
                        installation: 'ansible',
                        inventory: '/etc/ansible/inventory',
                        playbook: 'ansible/ansible_k8s_deploy_playbook.yaml'
                    )
                }
            }
        }
    }
}
```

<br>

###  Continuous Deployment with Ansible 
Generate ssh-keygen in Jenkins server  as a ec2-user
```
sudo su - ec2-user
pwd
# you should be in /home/ec2-user
ssh keygen
ls -la
cd .ssh/
cat id_rsa.pub
# copy this public key and paste in app server
sudo su - ec2-user
ls -la
cd .ssh/
vim authorized_keys
# open utils server
ssh ec2-user@appserver-publicip
# Ssh password less authentication established 
exit
cd /etc/ansible    #home directory for ansible inventory
sudo vim hosts
[appserver]
appserver-publicip  

ansible -i hosts -m ping all
```
1. Use Ansible to manage Kubernetes manifests stored in GitHub repositories.<br>
   a. Github url: https://github.com/kadivetikavya/PROJECTS/tree/main/ansible-k8s-CICD-project<br>
2. Deploy applications to the EKS cluster using Ansible playbook. <br>

### Accessing the Application
The application is now accessible to users via the external URL provided by the LoadBalancer
service. <br>
```
kubectl get all
```
Paste the following URL into your browser to see the running application: <br>
Loadbalancer url : a2a5e5f083b26430fadf920fe4f2a782-1459326598.us-east-1.elb.amazonaws.com













