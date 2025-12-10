terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# Data source to get the latest Ubuntu 20.04 AMI
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Create EBS volume for blockchain data
resource "aws_ebs_volume" "bitcoin_data" {
  availability_zone = var.availability_zone
  size              = var.ebs_volume_size
  type              = "gp3"
  encrypted         = true

  tags = {
    Name        = "${var.project_name}-data"
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

# Create EC2 instance
resource "aws_instance" "bitcoin_node" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = var.instance_type
  key_name      = var.key_pair_name

  availability_zone      = var.availability_zone
  vpc_security_group_ids = [aws_security_group.bitcoin_node.id]

  root_block_device {
    volume_size           = 20
    volume_type           = "gp3"
    encrypted             = true
    delete_on_termination = true
  }

  user_data = templatefile("${path.module}/scripts/user_data.sh", {
    bitcoin_version = var.bitcoin_version
    rpc_user        = var.rpc_user
    rpc_password    = var.rpc_password
    network         = var.network
    dbcache         = var.dbcache
    max_connections = var.max_connections
  })

  tags = {
    Name        = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
  }


}

resource "aws_volume_attachment" "bitcoin_data_attachment" {
  device_name = "/dev/sdf"
  volume_id   = aws_ebs_volume.bitcoin_data.id
  instance_id = aws_instance.bitcoin_node.id

  # Force detach if necessary
  force_detach = true
}

# Optional: Create Elastic IP for persistent public IP
resource "aws_eip" "bitcoin_node" {
  count    = var.create_elastic_ip ? 1 : 0
  instance = aws_instance.bitcoin_node.id
  domain   = "vpc"

  tags = {
    Name        = "${var.project_name}-eip"
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}
