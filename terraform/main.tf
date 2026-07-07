terraform {
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

# Latest Ubuntu 22.04 LTS in us-east-1
data "aws_ami" "ubuntu-22" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_instance" "wazuh-server" {
  ami                    = data.aws_ami.ubuntu-22.id
  instance_type          = var.instance_type
  key_name               = var.key_name
  subnet_id              = var.subnet_id
  vpc_security_group_ids = [aws_security_group.wazuh-server.id]

  root_block_device {
    # 20GB filled to 92% almost immediately — the base manager+indexer+dashboard
    # install alone takes ~12GB. Bumped 2026-07-07 after finding this the hard
    # way; gp3 is ~$0.08/GB/month, the extra 30GB is trivial compared to compute.
    volume_size = 50
    volume_type = "gp3"
  }

  tags = {
    Name    = "wazuh-server"
    Project = "wazuh-soc-lab"
  }
}

resource "aws_eip" "wazuh-server" {
  instance = aws_instance.wazuh-server.id
  domain   = "vpc"

  tags = {
    Name    = "wazuh-server-eip"
    Project = "wazuh-soc-lab"
  }
}
