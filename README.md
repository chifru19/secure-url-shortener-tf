# 🏗️ Architectural Overview: Secure URL Shortener (Terraform)

### Project Purpose
This project provides a Serverless Infrastructure-as-Code (IaC) solution for a secure URL shortening service. It is designed to be highly available, cost-effective, and secure by leveraging AWS cloud-native services.

### Proposed Tech Stack
* Infrastructure: Terraform (HashiCorp)
* Cloud Provider: AWS (Amazon Web Services)
* Compute: AWS Lambda (Serverless logic for redirection)
* Database: Amazon DynamoDB (NoSQL storage for URL mappings)
* API Layer: Amazon API Gateway
* Security: AWS IAM roles with "Least Privilege" access

### System Design
1. Request: A user hits a shortened URL via the API Gateway.
2. Processing: An AWS Lambda function triggers, querying DynamoDB for the original long URL.
3. Redirection: The Lambda returns a 301/302 redirect to the user's browser.
4. Logging: All interactions are logged via CloudWatch for security monitoring.

---
### 🛠️ Troubleshooting & Git Workflow
This repository was established following a systematic resolution of local Git blockages and remote synchronization errors. For a detailed breakdown of the troubleshooting process used to publish this project, see the [Git Workflow & Troubleshooting Case Study](https://github.com/chifru19/troubleshooting-case-study).
