#!/bin/bash

# Quick install of nginx (Amazon Linux 2 uses yum)
yum update -y
yum install -y nginx

# Make sure nginx starts on boot and is running now
systemctl enable nginx
systemctl start nginx

# Serve a basic static HTML file so the ALB has something to health check
cat <<EOF > /usr/share/nginx/html/index.html
<html>
  <head><title>Terraform Challenge</title></head>
  <body><h1>Hello from Terraform!</h1></body>
</html>
EOF

# NOTE: In production, we’d run certbot or use ACM + ALB to serve this over HTTPS