# ✅ Find the latest Ubuntu AMI
data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = [var.EC2_image]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical (official Ubuntu AMIs)
}

# ✅ Launch template (recipe for EC2 instances)
resource "aws_launch_template" "web_lt" {
  name_prefix   = "webserver-lt-"
  image_id      = data.aws_ami.ubuntu.id
  instance_type = var.instance_type
  key_name      = aws_key_pair.demo_key.key_name

  vpc_security_group_ids = [
    aws_security_group.port_22.id,
    aws_security_group.web_sg.id
  ]
user_data = base64encode(<<EOT
#!/bin/bash
# Update and install Apache + PHP
sudo apt-get update -y
sudo apt-get install -y apache2 php php-mysql curl unzip

# Get the API server private IP dynamically from Terraform
API_IP="${aws_instance.api_server.private_ip}"

# Create index.php that calls the API and prints JSON
sudo tee /var/www/html/index.php > /dev/null <<EOF
<?php
header('Content-Type: text/html');

// API endpoint using private IP from Terraform
\$api_ip = "${aws_instance.api_server.private_ip}";
\$api_url = "http://\$api_ip/api.php?action=get_all";

// Fetch JSON from API
\$response = @file_get_contents(\$api_url);
if (\$response === FALSE) {
    echo "Error contacting API server at \$api_url.";
} else {
    \$data = json_decode(\$response, true);
    echo "<pre>";
    print_r(\$data);
    echo "</pre>";
}
?>
EOF

# Remove default index.html if exists
sudo rm -f /var/www/html/index.html

# Set proper ownership and permissions
sudo chown -R www-data:www-data /var/www/html
sudo chmod -R 755 /var/www/html

# Enable and start Apache2
sudo systemctl enable apache2
sudo systemctl restart apache2
EOT
)


  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = var.instance_name
    }
  }
}

# ✅ Auto Scaling Group
resource "aws_autoscaling_group" "web_asg" {
  name                = "webserver-asg"
  desired_capacity    = 2
  min_size            = 2
  max_size            = 5
  vpc_zone_identifier = [aws_subnet.demo_subnet.id, aws_subnet.demo_subnet_b.id]
  health_check_type   = "EC2"
  force_delete        = true

  instance_refresh {
    strategy = "Rolling"
    preferences {
      min_healthy_percentage = 50
    }
  }

  launch_template {
    id      = aws_launch_template.web_lt.id
    version = "$Latest"
  }

  target_group_arns = [aws_lb_target_group.demo_tg.arn]

  tag {
    key                 = "Name"
    value               = var.instance_name
    propagate_at_launch = true
  }
}

# ✅ Scaling policy: add 1 instance when CPU > 70%
resource "aws_autoscaling_policy" "scale_out" {
  name                   = "scale-out-policy"
  scaling_adjustment     = 1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.web_asg.name
}

# ✅ Scaling policy: remove 1 instance when CPU < 20%
resource "aws_autoscaling_policy" "scale_in" {
  name                   = "scale-in-policy"
  scaling_adjustment     = -1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.web_asg.name
}

# ✅ CloudWatch Alarm: Scale out when CPU > 70%
resource "aws_cloudwatch_metric_alarm" "cpu_high" {
  alarm_name          = "webserver-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 60
  statistic           = "Average"
  threshold           = 70
  alarm_actions       = [aws_autoscaling_policy.scale_out.arn]

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.web_asg.name
  }

  treat_missing_data = "notBreaching"
}

# ✅ CloudWatch Alarm: Scale in when CPU < 20%
resource "aws_cloudwatch_metric_alarm" "cpu_low" {
  alarm_name          = "webserver-cpu-low"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 1
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 60
  statistic           = "Average"
  threshold           = 20
  alarm_actions       = [aws_autoscaling_policy.scale_in.arn]

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.web_asg.name
  }

  treat_missing_data = "notBreaching"
}
