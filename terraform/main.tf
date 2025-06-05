provider "aws" {
  region = "ap-northeast-2"
}

resource "aws_launch_template" "tracking" {
  name_prefix   = "tracking-launch-"
  image_id      = var.ami
  instance_type = "t2.micro"
  key_name      = var.key_name

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "tracking-ec2"
    }
  }
}

resource "aws_autoscaling_group" "tracking_asg" {
  desired_capacity     = 2
  max_size             = 4
  min_size             = 2

  vpc_zone_identifier = [var.subnet_a, var.subnet_b]

  launch_template {
    id      = aws_launch_template.tracking.id
    version = "$Latest"
  }

  target_group_arns = [aws_lb_target_group.main.arn]
}

resource "aws_lb_target_group" "main" {
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

