# Application Load Balancer
resource "aws_lb" "demo_alb" {
  name               = "demo-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = [aws_subnet.demo_subnet.id, aws_subnet.demo_subnet_b.id]

  enable_deletion_protection = false

  tags = {
    Name = "DemoALB"
  }
}

# Target group (ASG instances will register here automatically)
resource "aws_lb_target_group" "demo_tg" {
  name     = "demo-tg"
  port     = var.http_port
  protocol = "HTTP"
  vpc_id   = aws_vpc.demo_vpc.id

  health_check {
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }

  tags = {
    Name = "DemoTG"
  }
}

# Listener for HTTP
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.demo_alb.arn
  port              = var.http_port
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.demo_tg.arn
  }
}

output "alb_dns_name" {
  value = aws_lb.demo_alb.dns_name
}
