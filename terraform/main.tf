provider "aws" {
  region = "ap-northeast-2"
}

# 최신 Ubuntu AMI 자동 검색
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
}

# 프라이빗 서브넷 자동 검색 (태그 기준: Tier = private)
data "aws_subnet_ids" "private" {
  vpc_id = var.vpc_id

  tags = {
    Tier = "private"
  }
}

# Launch Template
resource "aws_launch_template" "tracking" {
  name_prefix   = "tracking-launch-"
  image_id      = data.aws_ami.ubuntu.id
  instance_type = "t2.micro"
  key_name      = var.key_name

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "tracking-ec2"
    }
  }
}

# Auto Scaling Group (2개 EC2 시작)
resource "aws_autoscaling_group" "tracking_asg" {
  desired_capacity     = 2
  max_size             = 4
  min_size             = 2

  vpc_zone_identifier = data.aws_subnet_ids.private.ids

  launch_template {
    id      = aws_launch_template.tracking.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "tracking-ec2"
    propagate_at_launch = true
  }
}
