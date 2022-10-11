terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }

  required_version = ">= 1.3.0"
}

provider "aws" {
  profile = var.profile
  region = "us-east-1"
}

##
## VPC with one public subnet
##

resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "server-perf-testing"
  }
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "server-perf-testing"
  }
}

resource "aws_subnet" "main" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.0.0/20"
  map_public_ip_on_launch = true

  tags = {
    Name = "server-perf-testing"
  }
}

resource "aws_route_table" "main" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "server-perf-testing"
  }
}

resource "aws_route_table_association" "main" {
  subnet_id = aws_subnet.main.id
  route_table_id = aws_route_table.main.id
}

resource "aws_route" "igw" {
  destination_cidr_block = "0.0.0.0/0"
  route_table_id = aws_route_table.main.id
  gateway_id = aws_internet_gateway.gw.id
}

##
## Security Group for EC2 instance
##

resource "aws_security_group" "ec2" {
  name        = "server-perf-testing"
  description = "HTTP server perf testing"
  vpc_id      = aws_vpc.main.id

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "server-perf-testing"
  }
}

resource "aws_security_group_rule" "ec2" {
  type              = "ingress"
  protocol          = "-1"
  from_port        = 0
  to_port          = 0
  cidr_blocks       = [aws_vpc.main.cidr_block]
  security_group_id = aws_security_group.ec2.id
}

resource "aws_security_group_rule" "ssh_in" {
  type              = "ingress"
  protocol          = "tcp"
  from_port         = 22
  to_port           = 22
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.ec2.id
}


##
## IAM
##

resource "aws_iam_role" "ec2" {
  name = "server-perf-testing"
  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": "sts:AssumeRole",
            "Principal": {
               "Service": "ec2.amazonaws.com"
            },
            "Effect": "Allow",
            "Sid": ""
        }
    ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "ec2" {
  role       = aws_iam_role.ec2.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "ec2" {
  name = "server-perf-testing"
  role = aws_iam_role.ec2.name

  depends_on = [
    aws_iam_role_policy_attachment.ec2
  ]
}

##
## Launch templates
##

resource "aws_placement_group" "ec2" {
  name     = "server-perf-testing"
  strategy = "cluster"
}

data "aws_ami" "amzn2" {
  owners = ["amazon"]
  most_recent = true

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-ebs"]
  }
}


resource "aws_launch_template" "target" {
  name = "server-perf-testing-target"
  image_id = data.aws_ami.amzn2.id
  instance_type = "m6i.large"
  update_default_version = true

  block_device_mappings {
    device_name = "/dev/xvda"

    ebs {
      volume_size = 30
      volume_type = "gp3"
    }
  }

  iam_instance_profile {
    arn = aws_iam_instance_profile.ec2.arn
  }

  network_interfaces {
    security_groups = [aws_security_group.ec2.id]
    associate_public_ip_address = true
  }

  monitoring {
    enabled = true
  }

  user_data = base64encode(templatefile("${path.module}/user_data.sh.tftpl", {
    ssh_public_key = var.ssh_public_key
    username = var.username
  }))
}

##
## EC2 instances
##

resource "aws_instance" "target" {
  placement_group = aws_placement_group.ec2.id
  subnet_id = aws_subnet.main.id

  launch_template {
    id = aws_launch_template.target.id
  }

  tags = {
    Name = "server-perf-testing-target"
  }
}

resource "aws_instance" "source" {
  placement_group = aws_placement_group.ec2.id
  subnet_id = aws_subnet.main.id
  instance_type = "m6i.4xlarge"

  launch_template {
    id = aws_launch_template.target.id
  }

  tags = {
    Name = "server-perf-testing-source"
  }
}
