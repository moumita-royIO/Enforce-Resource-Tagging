# AWS Real-Time Resource Tagging Enforcement

## Overview
This project demonstrates a **real-time tagging enforcement solution** using **AWS CloudTrail, EventBridge, Lambda, and S3**.  
It ensures that newly created AWS resources (EC2, RDS, S3) comply with mandatory tagging policies. Resources without required tags can be automatically terminated or flagged.

The following **mandatory tags** were checked using Python Logic with Boto3:

- `Environment` – Identifies the environment (e.g., Dev, QA, Prod)
- `Owner` – The responsible person or team
- `Keep_Until` – Indicates the resource expiration or retention date

---

## Architecture

1. **CloudTrail Trail**  
   - Tracks all management API calls across AWS accounts and regions.
   - Delivers events to **EventBridge** in near real-time.

2. **EventBridge Rule**  
   - Matches resource creation events (e.g., `CreateInstance`, `CreateDBInstance`, `CreateBucket`).
   - Triggers a **Lambda function** to enforce tagging policy.

3. **Lambda Function**  
   - Checks if required tags are present on newly created resources.
   - Takes automated action (terminate EC2, delete RDS/S3) if tags are missing.
   - Logs actions to **CloudWatch**.

4. **S3 Bucket**  
   - Stores CloudTrail logs for auditing and troubleshooting.
   - Bucket policy ensures CloudTrail has write permissions.

<img width="320" height="708" alt="enforce_tagging_architecture drawio" src="https://github.com/user-attachments/assets/35f95713-d8df-4911-965a-5e3e6793ad92" />

---

## Features
- **Real-time enforcement** of tagging policies.
- **Supports EC2, RDS, S3**.
- **Secure IAM roles** with least-privilege permissions.
   - Lambda execution role has least privilege for resource operations.Lambda only has permissions it needs: DescribeInstances, TerminateInstances, etc.
   - CloudTrail role has permission to write logs to S3 only.
- **S3 Bucket Policy** Only CloudTrail service can write logs.Enforces bucket-owner-full-control.
- **Auditable with CloudWatch Logs**Lambda logs are captured for audit, troubleshooting, and security review. All events logged via CloudTrail in S3.

---

## Terraform Infrastructure
- `aws_s3_bucket` – CloudTrail log storage.
- `aws_s3_bucket_policy` – grants CloudTrail write access.
- `aws_iam_role` – for Lambda execution and CloudTrail service.
- `aws_iam_policy` – least-privilege Lambda permissions.
- `aws_cloudtrail` – trail creation.
- `aws_cloudwatch_log_group` (optional) – Lambda logging.
- `aws_lambda_function` – enforces tagging.
- `aws_eventbridge_rule` – triggers Lambda on resource creation.

---

## Why CloudTrail + EventBridge vs AWS Config
- **Real-time enforcement** on API calls.
- Lower latency for automated action on resource creation.
- AWS Config is better suited for historical tracking and compliance auditing, but this project focuses on **instant enforcement**.

---

## Prerequisites
- Terraform 1.x
- AWS CLI configured with sufficient permissions
- AWS account with access to create IAM roles, Lambda, S3, CloudTrail

---

## Usage
1. Clone the repository.
2. Update `variables.tf` with your **bucket name**, **Lambda settings**, and **resource tags**.
3. Initialize Terraform:
   ```bash
   terraform init
   ```
4. Apply infrastructure:
   ```bash
   terraform apply
   ```
5. Test by creating a resource without tags and confirm Lambda enforces the policy. Sample log from my test is below:

   <img width="1514" height="543" alt="image" src="https://github.com/user-attachments/assets/1f2a4ea4-698c-440c-b14a-51ddde72869f" />
