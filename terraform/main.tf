
# Security group to allow HTTP (for now...)

resource "aws_security_group" "web_sg" {
  name   = "web-sg"
  vpc_id = aws_vpc.main.id

  ingress {
    description = "Allow HTTP (port 80) from anywhere"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # open for demo purposes

    # In production: this would be restricted to specific IPs or go through CloudFront
    # And we’d serve traffic over HTTPS (port 443) with TLS certs
  }

  egress {
    description = "Allow everything outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "coalfire-web-sg"
  }
}

# EC2 instance (Amazon Linux 2) to serve static HTML
resource "aws_instance" "web" {
  ami                         = var.ami_id
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.public.id
  associate_public_ip_address = true
  security_groups             = [aws_security_group.web_sg.name]
  iam_instance_profile        = aws_iam_instance_profile.ec2_profile.name

  # On first boot, this runs a shell script to install nginx and drop a custom HTML file
  user_data = file("${path.module}/../scripts/user_data.sh")

  tags = {
    Name = "coalfire-web"
  }
}


# IAM role EC2 will assume (trust relationship)

resource "aws_iam_role" "ec2_role" {
  name = "coalfire-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = {
        Service = "ec2.amazonaws.com"
      },
      Action = "sts:AssumeRole"
    }]
  })

  tags = {
    Name = "coalfire-ec2-role"
  }
}

# IAM instance profile — EC2 uses this to attach the role

resource "aws_iam_instance_profile" "ec2_profile" {
  name = "coalfire-ec2-profile"
  role = aws_iam_role.ec2_role.name
}

# Attach a managed policy that lets EC2 reboot itself (for self-healing logic)

resource "aws_iam_policy_attachment" "ec2_permissions" {
  name       = "coalfire-ec2-fullaccess"
  roles      = [aws_iam_role.ec2_role.name]
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2FullAccess"
}