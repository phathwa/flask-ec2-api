# Provider configuration
provider "aws" {
  region = "eu-north-1"  # 
}

# Create a new key pair
resource "tls_private_key" "flask_key" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "aws_key_pair" "flask_key_pair" {
  key_name   = "flask-key-pair"
  public_key = tls_private_key.flask_key.public_key_openssh
}


# Create a new security group for the EC2 instance
resource "aws_security_group" "flask_sg" {
  name        = "flask_sg"
  description = "Allow HTTP and SSH access"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Create the EC2 instance
resource "aws_instance" "flask_instance" {
  ami           = "ami-02a0945ba27a488b7"  # Replace with a valid AMI ID for your region
  instance_type = "t3.micro"  # Free Tier eligible instance type
  key_name      = aws_key_pair.flask_key_pair.key_name  # Use the key pair created above
  security_groups = [aws_security_group.flask_sg.name]
  associate_public_ip_address = true

  tags = {
    Name = "Flask API Instance"
  }

  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              yum install -y python3
              pip3 install -r /home/ec2-user/flask-ec2-api/requirements.txt
              cd /home/ec2-user/flask-ec2-api
              python3 app.py &
              EOF
}

# Output the public IP of the created EC2 instance
output "instance_public_ip" {
  value = aws_instance.flask_instance.public_ip
}
