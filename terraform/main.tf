provider "aws" {
  region = "ap-northeast-2"
}

# 최신 Ubuntu AMI 가져오기
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
}

# 프라이빗 서브넷 자동 추출 (태그 필수: Tier=private)
data "aws_subnet_ids" "private" {
  vpc_id = var.vpc_id
  tags = {
    Tier = "private"
  }
}

# ALB용 퍼블릭 서브넷 추출 (태그 필수: Tier=public)
data "aws_subnet_ids" "public" {
  vpc_id = var.vpc_id
  tags = {
    Tier = "public"
  }
}

# ALB
resource "aws_lb" "app_alb" {
  name               = "tracking-alb"
  load_balancer_type = "application"
  subnets            = data.aws_subnet_ids.public.ids
  security_groups    = [] # 따로 지정하거나 기본 허용 SG 사용
}

# Target Group
resource "aws_lb_target_group" "app_tg" {
  name     = "tracking-tg"
  port     = 3000
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  health_check {
    path                = "/"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

# ALB Listener
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.app_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app_tg.arn
  }
}

# EC2 Launch Template
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

# Auto Scaling Group
resource "aws_autoscaling_group" "tracking_asg" {
  desired_capacity     = 2
  max_size             = 4
  min_size             = 2
  vpc_zone_identifier  = data.aws_subnet_ids.private.ids

  launch_template {
    id      = aws_launch_template.tracking.id
    version = "$Latest"
  }

  target_group_arns = [aws_lb_target_group.app_tg.arn]

  tag {
    key                 = "Name"
    value               = "tracking-ec2"
    propagate_at_launch = true
  }
}
