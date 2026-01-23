# Automated Secure Software Delivery Using GitOps on AWS EKS 

## Project Overview
Designed and implemented an enterprise-grade end-to-end DevSecOps CI/CD pipeline with GitOps-driven Kubernetes deployments, integrating automated security scans and continuous delivery.<br>

This project aims to achieve the following goals:


### 1. Continuous Integration (CI): 
a. Automate the process of code integration, ensuring that new code changes are seamlessly merged with the existing codebase. <br>
b. Perform automated code quality checks and static analysis using SonarQube. 


### 2. Continuous Deployment (CD):
a. Automatically deploy applications to a Kubernetes cluster without manual effort. <br>
b. Use Docker to package applications so they run the same way in development, testing, and production.<br>
c. Manage deployment changes by updating configuration files and pushing them to Git, so every change is tracked and easy to roll back.<br><br>

## Tech Stack Used
<img width="1536" height="674" alt="3 drawio" src="https://github.com/user-attachments/assets/9c55d1c7-664f-4253-b84d-ef753aeb727d" /> 

## Architecture Diagram
<img width="1853" height="541" alt="2 drawio" src="https://github.com/user-attachments/assets/482b069a-a02c-4c44-bac0-09a97751f4e7" /> <br> <br>


## Core Components and Workflow
1. Source Code Management: Developers push code to a GitHub repository.
2. CI Trigger: A webhook from GitHub triggers a pipeline job on the Jenkins CI/CD server.
3. Build & Analyze: Jenkins checks out the code, compiles it using Maven, and runs a static code analysis scan with SonarQube.
4. Containerize & Scan: A Docker image is built from the application code. This image is then scanned for known vulnerabilities using Trivy.
5. Store Artifact: If the scans pass, the validated Docker image is pushed to a container registry, such as Docker Hub.
6. GitOps Trigger: The CI pipeline automatically updates a Kubernetes manifest file in a separate Git repository (the "Config Repo"), pointing to the new Docker image tag.
7. Deploy & Orchestrate: Argo CD, a GitOps tool, detects the change in the Config Repo and automatically synchronizes the state of the Kubernetes cluster to match the desired state defined in the manifests, deploying the new version of the application. <br><br>

## Prerequisites and Environment Setup
1. GitHub Account: To host the application source code and the Kubernetes configuration repositories. A free account is sufficient for public repositories.<br>
2. Docker Hub Account: To store and distribute the container images. A free account provides public repositories.<br>
3. Cloud Provider / Kubernetes Environment: Access to a Kubernetes cluster. Options include:<br>
  a. Local Development: gitbash or visual studio for local testing.<br>
  b. Cloud-Managed: Amazon Elastic Kubernetes Service (EKS) for more robust, production-like environments.<br><br>

## Infrastructure and Tool Installation
A Linux server for Jenkins , Docker, Sonarqube setup with an instance type "t2.Xlarge" and a EKS Cluster to deploy container application.<br>

### Jenkins Server Setup
```
#Install jenkins on your linux system
sudo yum update –y
sudo wget -O /etc/yum.repos.d/jenkins.repo \
    https://pkg.jenkins.io/redhat-stable/jenkins.repo
sudo rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io-2023.key
sudo yum upgrade
sudo yum install java-17-amazon-corretto -y
sudo yum install jenkins -y
sudo systemctl enable jenkins
sudo systemctl start jenkins
sudo systemctl status jenkins
```

### Installation & configuration of docker
```
#Install Docker and configure it to work with Jenkins
sudo yum install docker -y
sudo systemctl start docker
sudo usermod -aG docker jenkins
sudo usermod -aG docker ec2-user
sudo systemctl restart docker
sudo chmod 666 /var/run/docker.sock
```


### AWS CLI configuration
```
#Configure AWS CLI to interact with AWS services
aws configure
# Enter your AWS
Access Key ID, Secret Access Key, region, and output format when prompted
```


### Kubectl and EKSCTL installation
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
eksctl create cluster --name myappcluster --nodegroup-name myappng --node-type t3.micro --nodes 8 --managed 
```


### Install Required Jenkins Plugins 
#### Install the Docker plugin in Jenkins: 
1. Go to Jenkins Dashboard > Manage Jenkins > Manage Plugins > Available. <br>
2. Install the Docker plugin,Pipeline stage view,blue ocean..etc <br>

### Install and configure Sonarqube as a Docker container 
```
Docker run --itd  --name sonar -p 9000:9000 sonarqube
```
1. Check if the SonarQube container is running: <br>
```
docker ps
```
2. Access the SonarQube web interface: <br>
   a. Open a web browser and go to http://<your-server-ip>:9000 <br>
   b. The default login credentials are: <br>
3. Username: admin <br>
4. Password: admin <br>
5. Log in to SonarQube using the default credentials. <br>
   a. Change the default password <br>
6. Create Sonar token for Jenkins: <br>
Sonar Dashboard -> Administration -> MyAccount -> Security -> Create token  <br>

### Generate GitHub Token 
Generate a GitHub token for Jenkins to access your GIT repositories: <br>
1. Go to GitHub > Settings > Developer settings > Personal access tokens.  <br>
2. Generate a new token with the necessary scopes (e.g., repo, admin:repo_hook).<br><br>
   
### Create Jenkinsfile for CI/CD Pipeline 
Create a Jenkinsfile in your repository to define the CI/CD pipeline: <br>
```
pipeline {
    agent any

    
    tools {
        maven 'maven3'
    }

    stages {

        stage('Checkout') {
            steps {
                echo 'Cloning GIT HUB Repo'
                git branch: 'main',
                    url: 'https://github.com/kadivetikavya/mindcircuit13.git'
            }
        }

        stage('SonarQube Scan') {
            steps {
                echo 'Scanning project'
                sh 'ls -lrth'
                sh '''
                    mvn sonar:sonar \
                    -Dsonar.host.url=http://34.207.182.118:9000/ \
                    -Dsonar.login=squ_06428ecf7189debd6d825ba23b35aacf574e7d43
                '''
            }
        }

        stage('Build Artifact') {
            steps {
                echo 'Build Artifact'
                sh 'mvn clean package'
            }
        }

        stage('Build Docker Image') {
            steps {
                echo 'Build Docker Image'
                sh 'docker build -t kadivetikavya/kadi-repo:${BUILD_NUMBER} .'
            }
        }
		
		
		stage('trivy image scan vulnerabilities ') {
            steps {
                echo 'Scanning Docker image for vulnerabilities'
                sh '''
                trivy image \
                  --severity HIGH,CRITICAL \
                  --exit-code 1 \
                  --no-progress \
                  kadivetikavya/kadi-repo:${BUILD_NUMBER}
                '''
            }
        }

        stage('Push to Docker Hub') {
            steps {
                script {
                    withCredentials([
                        string(credentialsId: 'dockerhub', variable: 'dockerhub')
                    ]) {
                        sh 'docker login -u kadivetikavya -p ${dockerhub}'
                    }

                    sh 'docker push kadivetikavya/kadi-repo:${BUILD_NUMBER}'
                    echo 'Pushed to Docker Hub'
                }
            }
        }

        stage('Update Deployment File') {
            environment {
                GIT_REPO_NAME = 'mindcircuit13'
                GIT_USER_NAME = 'kadivetikavya'
            }

            steps {
                echo 'Update Deployment File'

                withCredentials([
                    string(credentialsId: 'githubtoken', variable: 'githubtoken')
                ]) {
                    sh '''
                        git config user.email "kadivetikavya@gmail.com"
                        git config user.name "kadivetikavya"

                        sed -i "s/kadi-repo:.*/kadi-repo:${BUILD_NUMBER}/g" deploymentfiles/deployment.yml

                        git add .
                        git commit -m "Update deployment image to version ${BUILD_NUMBER}"

                        git push https://${githubtoken}@github.com/${GIT_USER_NAME}/${GIT_REPO_NAME} HEAD:main
                    '''
                }
            }
        }

    }
} 

```


#### Explanation of Each Stage 
1. Checkout 
   a. Clones the main branch of the specified GitHub repository to the Jenkins workspace. 
2. SonarQube Scan <br>
   a. Lists the directory contents to ensure files are in place. <br>
   b. Runs a SonarQube scan using Maven to analyze the code for bugs, vulnerabilities, and code smells. The scan results are sent to the specified  SonarQube server. <br>
3. Build Artifact 
   a. Cleans the workspace and packages the Maven project, creating a build artifact (typically a JAR or WAR file). <br>
4. Build Docker Image <br>
   a. Builds a Docker image from the Dockerfile in the project directory. <br>
   b. Tags the Docker image with the Jenkins build number for versioning. <br>
   c. Trivy is an image scan on the specified image and fail the build if critical issues are found in image. <br>
5. Push to Docker Hub <br>
   a. Logs into Docker Hub using credentials stored in Jenkins.<br>
   b. Pushes the Docker image to the Docker Hub repository. <br>
6. Update Deployment File <br>
   a. Configures git user details for committing changes. <br>
   b. Updates the deployment YAML file to use the newly created Docker image with the current build number. <br>
   c. Stages, commits, and pushes the updated deployment file back to the GitHub repository, ensuring the Kubernetes cluster can pull the latest image. <br>


<img width="1059" height="309" alt="image" src="https://github.com/user-attachments/assets/62cd55bc-8806-4efc-abcf-e62d14cdb33b" />


### Kubernetes Deployment and Service Files 
1. Installation of argocd:
```
kubectl create namespace argocd 
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
```
2. Edit the Argo CD server service to type LoadBalancer: 
```
kubectl patch svc argocd-server -n argocd -p '{"spec": {"type": "LoadBalancer"}}' 
kubectl get svc argocd-server -n argocd 
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d ; echo 
```

#### Create deployment.yaml and service.yaml in your repository to define the Kubernetes resources: 

### deployment.yml:
```
--- 
apiVersion: apps/v1 
kind: Deployment 
metadata: 
  name: my-app 
  labels: 
    app: my-app 
spec: 
  replicas: 2 
  selector: 
    matchLabels: 
      app: my-app 
  template: 
    metadata: 
      labels: 
        app: my-app 
    spec: 
      containers: 
      - name: my-app 
        image: kadivetikavya/kadi-repo:tag 
        ports: 
        - containerPort: 8080 
```

### service.yml: 
```
---
apiVersion: v1 
kind: Service 
metadata: 
  name: my-app-service 
spec: 
  type: LoadBalancer 
  ports: 
  - name: http 
    port: 80 
    targetPort: 8080 
    protocol: TCP 
selector: 
 app: my-app
```

### Creating the Application in Argo CD
You can define an Argo CD application declaratively with a YAML manifest or through theArgo CD UI.<br>
#### Using the Argo CD UI
1. Log in to your Argo CD UI.<br>
2. Click on + NEW APP.<br>
3. Fill in the application details:<br>
   a. Application Name: my-app<br>
   b. Project: default<br>
   c. Sync Policy: Automatic<br>
   d. Check Prune Resources and Self Heal for a fully automated GitOps experience.<br>
4. Configure the Source:<br>
   a. Repository URL: The URL of your Config Repo (e.g.,https://github.com/your-github-username/my-app-config.git).<br>
   b. Revision: HEAD (or your main branch name).<br>
   c. Path: The path to the manifests for this specific application (e.g., my-app).<br>
5. Configure the Destination:<br>
   a. Cluster URL: https://kubernetes.default.svc (for in-cluster deployment).<br>
   b. Namespace: The Kubernetes namespace where you want to deploy the app (e.g.,production). Ensure this namespace exists.<br>
6. Click the CREATE button.<br>

<img width="701" height="369" alt="image" src="https://github.com/user-attachments/assets/87639091-39e9-4a37-a7d0-498217508b68" />

## Project Conclusion
By following these phases, an organization can establish a highly automated, secure, and efficient workflow for developing and deploying containerized applications on Kubernetes.
