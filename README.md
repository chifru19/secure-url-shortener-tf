🏗️ Secure URL Shortener | AWS Serverless IaC
📖 Project Overview
This repository contains a production-grade, serverless Infrastructure-as-Code (IaC) solution for a secure URL shortening service. By leveraging AWS cloud-native services, this architecture eliminates server management overhead, reduces the attack surface, and ensures 99.9% availability.

🛠️ Tech Stack
Infrastructure: Terraform (HashiCorp)

Cloud Provider: AWS (Amazon Web Services)

Compute: AWS Lambda (Python-based redirection logic)

Database: Amazon DynamoDB (Encrypted NoSQL storage)

API Layer: Amazon API Gateway

Security & Audit: tfsec (Static Analysis), AWS IAM (Least Privilege)

🏗️ Architectural Design & Security Flow
The system follows a strictly decoupled serverless pattern to ensure high performance and deep observability.

Ingress: A user requests a shortened URL via Amazon API Gateway.

Execution: An AWS Lambda function is triggered, assuming a granular IAM role to query the database.

Data Retrieval: The function fetches the original URL from an encrypted DynamoDB table.

Egress: The system issues a 301/302 redirect.

Telemetry: All request metadata and system logs are streamed to CloudWatch and integrated with the Sentinel Fortress (Splunk SOC Lab) for threat detection.

🔐 Security Hardening (tfsec Audited)
This project has been hardened against common cloud misconfigurations. Key security features include:

Encryption at Rest: DynamoDB utilizes AWS-managed CMKs to protect data.

Point-in-Time Recovery (PITR): Enabled for DynamoDB to ensure data resilience against accidental deletion or ransomware.

S3 Public Access Block: Strict bucket policies to prevent unauthorized data exposure.

Automated SAST: Integrated GitHub Actions with tfsec to prevent the deployment of insecure infrastructure.

🚀 Setup & Deployment
Prerequisites
Terraform v1.0+

AWS CLI configured with appropriate credentials.

Installation
Bash
# Clone the repository
git clone https://github.com/chifru19/secure-url-shortener-tf.git
cd secure-url-shortener-tf

# Initialize Terraform
terraform init

# Plan and Apply
terraform plan
terraform apply
🕵️‍♂️ Git Workflow & Troubleshooting
This repository serves as a case study in resolving complex version control conflicts and "Shift Left" security implementation. For a detailed breakdown of the troubleshooting process, see the Git Workflow & Troubleshooting Case Study.

👨‍💻 Engineering
Frank Fru

Portfolio: frankfru.com

GitHub: chifru19

LinkedIn: linkedin.com/in/frank-fru