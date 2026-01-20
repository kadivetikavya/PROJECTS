# Automated Secure Software Delivery Using GitOps on AWS EKS

## Project Overview
Designed and implemented an enterprise-grade end-to-end DevSecOps CI/CD pipeline with GitOps-driven Kubernetes deployments, integrating automated security scans and continuous delivery.
This project aims to achieve the following goals:


### 1. Continuous Integration (CI): 
a. Automate the process of code integration, ensuring that new code changes are seamlessly merged with the existing codebase. 
b. Perform automated code quality checks and static analysis using SonarQube. 


### 2. Continuous Deployment (CD):
a. Automatically deploy applications to a Kubernetes cluster without manual effort.
b. Use Docker to package applications so they run the same way in development, testing, and production.
c. Manage deployment changes by updating configuration files and pushing them to Git, so every change is tracked and easy to roll back.

## Tech Stack Used
<img width="1331" height="662" alt="drawio" src="https://github.com/user-attachments/assets/d1a3936b-11b2-49a8-b23d-31b50bf971d3" />


## Architecture Diagram
<img width="1853" height="541" alt="2 drawio" src="https://github.com/user-attachments/assets/482b069a-a02c-4c44-bac0-09a97751f4e7" />


## Core Components and Workflow
1. Source Code Management: Developers push code to a GitHub repository.
2. CI Trigger: A webhook from GitHub triggers a pipeline job on the Jenkins CI/CD server.
3. Build & Analyze: Jenkins checks out the code, compiles it using Maven, and runs a static code analysis scan with SonarQube.
4. Containerize & Scan: A Docker image is built from the application code. This image is then scanned for known vulnerabilities using Trivy.
5. Store Artifact: If the scans pass, the validated Docker image is pushed to a container registry, such as Docker Hub.
6. GitOps Trigger: The CI pipeline automatically updates a Kubernetes manifest file in a separate Git repository (the "Config Repo"), pointing to the new Docker image tag.
7. Deploy & Orchestrate: Argo CD, a GitOps tool, detects the change in the Config Repo and automatically synchronizes the state of the Kubernetes cluster to match
   the desired state defined in the manifests, deploying the new version of the application.

## Project Conclusion
By following these phases, an organization can establish a highly automated, secure, and efficient workflow for developing and deploying containerized
applications on Kubernetes.
