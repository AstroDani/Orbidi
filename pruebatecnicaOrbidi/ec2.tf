data "aws_ssm_parameter" "ami_id" {
  name = "/aws/service/ecs/optimized-ami/amazon-linux/recommended/image_id"
}

resource "aws_iam_role" "ec2_role" {
  name = "EC2Role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action    = "sts:AssumeRole"
        Effect    = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_instance_profile" "ec2_instance_profile" {
  name = "EC2RoleInstanceProfile"
  role = aws_iam_role.ec2_role.name
}


resource "aws_iam_policy_attachment" "ec2_attachment" {
  name       = "ec2-attachment"
  roles = [aws_iam_role.ec2_role.name]
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

resource "aws_launch_template" "ecs" {
  name          = "ecs-launch-template"
  image_id      = data.aws_ssm_parameter.ami_id.value
  instance_type = var.instance_type
  iam_instance_profile {
    arn = aws_iam_instance_profile.ec2_instance_profile.arn
  }
  vpc_security_group_ids = [aws_security_group.ecs.id]

  user_data = base64encode(<<-EOF
              #!/bin/bash
              echo ECS_CLUSTER=${aws_ecs_cluster.main.name} >> /etc/ecs/ecs.config
              EOF
  )

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "ecs" {
  launch_template {
    id = aws_launch_template.ecs.id
    version = "$Latest"
  }
  min_size             = 2
  max_size             = 5
  desired_capacity     = 2
  vpc_zone_identifier  = aws_subnet.private[*].id
  protect_from_scale_in = true

}

resource "aws_security_group" "rds" {
  name = "rds-sg"
  vpc_id      = aws_vpc.main.id
  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    security_groups = [aws_security_group.ecs.id]
  }
}

resource "aws_security_group" "ecs" {
  name        = "ecs-sg"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "alb_sg" {
  vpc_id                      = aws_vpc.main.id
  name                        = "alb-sg"
  description                 = "Security group for alb"
  revoke_rules_on_delete      = true

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
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

resource "aws_lb" "main" {
  name               = "main-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = aws_subnet.public[*].id

  enable_deletion_protection = false
}

resource "aws_lb_target_group" "main" {
  name     = "main-target-group"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id
  target_type = "ip"

  health_check {
    interval            = 30
    path                = "/health"
    protocol            = "HTTP"
    timeout             = 15
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

resource "aws_lb_listener" "listener" {
  load_balancer_arn         = aws_lb.main.arn
  port                      = "80"
  protocol                  = "HTTP"

  default_action {
    type                    = "forward"
    target_group_arn        = aws_lb_target_group.main.arn
  }
}