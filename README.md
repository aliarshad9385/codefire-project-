# Coalfire Technical Challenge – Ali Arshad

This repository contains my solution to the Coalfire technical challenge. The goal was to provision a basic public-facing web service in AWS and implement lightweight monitoring and automated recovery.

## Overview

The infrastructure is defined using Terraform and includes:

- A VPC with a public subnet
- Internet Gateway and routing
- EC2 instance with public IP
- Application Load Balancer
- Security groups following least privilege
- IAM role and instance profile for EC2
- Optional S3 bucket for future log upload

The EC2 instance is bootstrapped with a shell script to install and start NGINX. A Python script is provided to monitor the web service and initiate an EC2 reboot if the service becomes unhealthy.

## Components

**Terraform**

Located in the `terraform/` directory. Infrastructure modules include:

- `main.tf` – Full infrastructure definition
- `variables.tf` – Configuration inputs
- `outputs.tf` – Key output values
- `providers.tf` – AWS provider block

**Shell Script**

`scripts/user_data.sh` contains the EC2 bootstrap logic. It installs NGINX and writes a static HTML page with expected content.

**Python Monitoring Script**

`scripts/monitor.py` checks the ALB endpoint for:

- HTTP 200 OK status
- Expected static content in the response

If either check fails, the script calls the AWS API to reboot the instance using `boto3`.

## Usage

To run the monitor locally:

```bash
python3 scripts/monitor.py http://<alb_dns> i-0example us-east-1# -coalfire-challenge

