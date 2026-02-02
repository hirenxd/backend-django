data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
}

resource "aws_launch_template" "lt" {
  name_prefix   = "${var.env}-lt"
  image_id      = data.aws_ami.ubuntu.id
  instance_type = var.instance_type

  vpc_security_group_ids = [var.ec2_sg_id]

  user_data = base64encode(<<EOF
#!/bin/bash
apt-get update -y
apt-get install -y nginx
systemctl start nginx
systemctl enable nginx
echo "Hello World from $(hostname)" > /var/www/html/index.html
EOF
  )
}

resource "aws_autoscaling_group" "asg" {
  name                = "${var.env}-asg"
  desired_capacity    = 1
  max_size            = 2
  min_size            = 0
  vpc_zone_identifier = var.private_subnet_ids

  target_group_arns = [var.target_group_arn]

  launch_template {
    id      = aws_launch_template.lt.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "${var.env}-app-instance"
    propagate_at_launch = true
  }
}
