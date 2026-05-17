# TrendStoreApp – End-to-End DevOps CI/CD Project

## Project Overview

This project demonstrates a complete DevOps workflow for deploying a production-ready static web application using Docker, Jenkins, Kubernetes (AWS EKS), Terraform, DockerHub, and monitoring tools.

The application source repository contains only the `dist/` folder, representing a production build output used for deployment practice.

The project focuses on:

* Docker containerization
* CI/CD pipeline automation
* Kubernetes deployment
* AWS EKS orchestration
* Jenkins integration with GitHub
* DockerHub image management
* Monitoring using Prometheus and Grafana

\---

# Technologies Used

|Technology|Purpose|
|-|-|
|GitHub|Source code management|
|Docker|Containerization|
|DockerHub|Container image registry|
|Jenkins|CI/CD automation|
|AWS EC2|Jenkins hosting|
|AWS EKS|Kubernetes cluster|
|kubectl|Kubernetes management|
|eksctl|EKS cluster creation|
|Terraform|Infrastructure provisioning|
|Prometheus|Monitoring|
|Grafana|Visualization dashboards|

\---

# Application Repository

Repository:

https://github.com/Kantimati1193/TrendStoreApp

\---

# Project Architecture

```text
GitHub
   ↓
Webhook Trigger
   ↓
Jenkins Pipeline
   ↓
Docker Build
   ↓
DockerHub Push
   ↓
Kubernetes Deployment (AWS EKS)
   ↓
Prometheus Monitoring
   ↓
Grafana Dashboard
```

\---

# Application Setup

## Clone Repository

```bash
git clone https://github.com/Vennilavanguvi/Trend.git
cd TrendStoreApp
```

## Verify dist Directory

```bash
ls
```

Expected:

```text
dist/
README.md
```

\---

# Docker Setup

## Dockerfile

```dockerfile
FROM nginx:alpine

RUN rm -rf /usr/share/nginx/html/\*

COPY dist/ /usr/share/nginx/html

EXPOSE 3000

RUN sed -i 's/listen       80;/listen       3000;/g' /etc/nginx/conf.d/default.conf

CMD \["nginx", "-g", "daemon off;"]
```

\---

## Build Docker Image

```bash
docker build -t trend-app .
```

## Run Docker Container

```bash
docker run -d -p 3000:3000 trend-app
```

Application URL:

```text
http://localhost:3000
```

\---

# DockerHub Setup

## Login to DockerHub

```bash
docker login
```

## Tag Docker Image

```bash
docker tag trend-app kantimati/trend-app:latest
```

## Push Docker Image

```bash
docker push kantimati/trend-app:latest
```

DockerHub Repository:

https://hub.docker.com/

\---

# Terraform Infrastructure Setup

## main.tf

```hcl
provider "aws" {
  region = "ap-south-1"
}

resource "aws\_instance" "jenkins" {
  ami           = "ami-xxxxxxxx"
  instance\_type = "t3.small"

  tags = {
    Name = "Jenkins-Server"
  }
}
```

## Terraform Commands

```bash
terraform init
terraform plan
terraform apply
```

\---

# Jenkins Setup

## Install Java 21

```bash
sudo dnf install java-21-amazon-corretto -y
```

## Install Jenkins

```bash
sudo wget -O /etc/yum.repos.d/jenkins.repo \\
https://pkg.jenkins.io/redhat-stable/jenkins.repo

sudo rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io-2023.key

sudo dnf install jenkins -y
```

## Start Jenkins

```bash
sudo systemctl enable jenkins
sudo systemctl start jenkins
```

## Access Jenkins

```text
http://<EC2-PUBLIC-IP>:8080
```

\---

# Required Jenkins Plugins

Installed plugins:

* Git plugin
* Pipeline
* Docker Pipeline
* Kubernetes
* GitHub Integration Plugin

\---

# Docker Setup on Jenkins Server

## Install Docker

```bash
sudo dnf install docker -y
```

## Start Docker

```bash
sudo systemctl start docker
sudo systemctl enable docker
```

## Add Jenkins User to Docker Group

```bash
sudo usermod -aG docker jenkins
```

## Restart Services

```bash
sudo systemctl restart docker
sudo systemctl restart jenkins
```

\---

# AWS EKS Setup

## Install eksctl

```bash
curl --silent --location \\
"https://github.com/weaveworks/eksctl/releases/latest/download/eksctl\_$(uname -s)\_amd64.tar.gz" \\
| tar xz -C /tmp

sudo mv /tmp/eksctl /usr/local/bin
```

\---

## Install kubectl

```bash
curl -LO "https://dl.k8s.io/release/$(curl -L -s \\
https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"

chmod +x kubectl
sudo mv kubectl /usr/local/bin/
```

\---

## Configure AWS CLI

```bash
aws configure
```

\---

## Create EKS Cluster

```bash
eksctl create cluster \\
--name trend-cluster \\
--region ap-south-1 \\
--node-type t3.medium \\
--nodes 2
```

\---

## Verify Cluster

```bash
kubectl get nodes
```

\---

# Kubernetes Deployment

## deployment.yaml

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: trend-app
spec:
  replicas: 2
  selector:
    matchLabels:
      app: trend
  template:
    metadata:
      labels:
        app: trend
    spec:
      containers:
      - name: trend
        image: kantimati/trend-app:latest
        ports:
        - containerPort: 3000
```

\---

## service.yaml

```yaml
apiVersion: v1
kind: Service
metadata:
  name: trend-service
spec:
  type: LoadBalancer
  selector:
    app: trend
  ports:
    - port: 80
      targetPort: 3000
```

\---

## Deploy Application

```bash
kubectl apply -f deployment.yaml
kubectl apply -f service.yaml
```

## Verify Pods

```bash
kubectl get pods
```

## Verify Service

```bash
kubectl get svc
```

\---

# Jenkins CI/CD Pipeline

## Jenkinsfile

```groovy
pipeline {
    agent any

    environment {
        IMAGE\_NAME = "kantimati/trend-app"
    }

    stages {

        stage('Build Docker Image') {
            steps {
                sh 'docker build -t $IMAGE\_NAME:latest .'
            }
        }

        stage('Docker Login') {
            steps {
                withCredentials(\[usernamePassword(
                    credentialsId: 'dockerhub-creds',
                    usernameVariable: 'DOCKER\_USER',
                    passwordVariable: 'DOCKER\_PASS'
                )]) {

                    sh 'echo $DOCKER\_PASS | docker login -u $DOCKER\_USER --password-stdin'
                }
            }
        }

        stage('Push Docker Image') {
            steps {
                sh 'docker push $IMAGE\_NAME:latest'
            }
        }

        stage('Deploy to Kubernetes') {
            steps {
                sh '''
                export AWS\_SHARED\_CREDENTIALS\_FILE=/var/lib/jenkins/.aws/credentials
                export AWS\_CONFIG\_FILE=/var/lib/jenkins/.aws/config
                export KUBECONFIG=/var/lib/jenkins/.kube/config

                kubectl apply -f deployment.yaml
                kubectl apply -f service.yaml
                '''
            }
        }
    }
}
```

\---

# GitHub Webhook Integration

## Webhook URL

```text
http://<JENKINS-PUBLIC-IP>:8080/github-webhook/
```

## Trigger Configuration

Enabled:

```text
GitHub hook trigger for GITScm polling
```

\---

# Monitoring Setup

## Install Helm

```bash
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
```

\---

## Add Prometheus Repository

```bash
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
```

\---

## Create Monitoring Namespace

```bash
kubectl create namespace monitoring
```

\---

## Install Monitoring Stack

```bash
helm install monitoring prometheus-community/kube-prometheus-stack \\
-n monitoring
```

\---

## Verify Monitoring Pods

```bash
kubectl get pods -n monitoring
```

\---

## Expose Grafana

```bash
kubectl edit svc monitoring-grafana -n monitoring
```

Change:

```yaml
type: ClusterIP
```

to:

```yaml
type: LoadBalancer
```

\---

## Get Grafana Password

```bash
kubectl get secret --namespace monitoring monitoring-grafana \\
-o jsonpath="{.data.admin-password}" | base64 --decode ; echo
```

Username:

```text
admin
```

\---

# Useful Commands

## Check Pods

```bash
kubectl get pods
```

## Check Services

```bash
kubectl get svc
```

## Check Nodes

```bash
kubectl get nodes
```

## Check Monitoring Pods

```bash
kubectl get pods -n monitoring
```

\---

# Challenges Faced and Fixes

|Issue|Resolution|
|-|-|
|Jenkins Java version mismatch|Installed Java 21|
|Jenkins node offline|Increased disk space and cleaned temp storage|
|Docker permission denied|Added Jenkins user to docker group|
|GitHub master/main mismatch|Updated branch configuration to main|
|Kubernetes authentication failure|Configured AWS and kubeconfig for Jenkins user|
|Jenkins unable to access EKS|Exported KUBECONFIG and AWS paths in Jenkinsfile|

\---

# Outcome

Successfully implemented:

* Dockerized application deployment
* Automated Jenkins CI/CD pipeline
* DockerHub integration
* Kubernetes deployment using AWS EKS
* GitHub webhook automation
* Monitoring with Prometheus and Grafana

\---

# 

