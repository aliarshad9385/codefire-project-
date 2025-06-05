#!/usr/bin/env python3

import boto3
import requests
import time
import sys
import logging
from botocore.exceptions import ClientError

# Logging setup
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s",
    handlers=[logging.StreamHandler()]
)

EXPECTED_STRING = "Hello from Terraform!"
CHECK_INTERVAL = 10  # how often we check (in seconds)

def health_check(target_url: str) -> bool:
    """Ping the URL and check both status code and content."""
    try:
        response = requests.get(target_url, timeout=5)
        if response.status_code != 200:
            logging.warning(f"Non-200 response: {response.status_code}")
            return False

        if EXPECTED_STRING not in response.text:
            logging.warning("Expected content not found in response.")
            return False

        return True

    except requests.exceptions.RequestException as e:
        logging.error(f"HTTP check failed: {e}")
        return False

def reboot_instance(instance_id: str, region: str):
    """Trigger a reboot using the AWS EC2 API."""
    ec2 = boto3.client("ec2", region_name=region)
    try:
        ec2.reboot_instances(InstanceIds=[instance_id])
        logging.info(f"Instance reboot triggered: {instance_id}")
    except ClientError as e:
        logging.error(f"Reboot failed: {e}")

def main():
    if len(sys.argv) != 4:
        print("Usage: python monitor.py <alb_url> <instance_id> <aws_region>")
        sys.exit(1)

    alb_url = sys.argv[1]
    instance_id = sys.argv[2]
    aws_region = sys.argv[3]

    logging.info(f"Monitoring {alb_url} for health...")
    while True:
        if not health_check(alb_url):
            logging.warning("Health check failed. Rebooting instance.")
            reboot_instance(instance_id, aws_region)
        else:
            logging.info("Health check passed.")
        time.sleep(CHECK_INTERVAL)

if __name__ == "__main__":
    main() 