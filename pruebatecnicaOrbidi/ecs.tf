data "aws_ssm_parameter" "ecr_url" {
  name = "orbidi-api-ecr-repository-url"
}

resource "aws_ecs_cluster" "main" {
  name = "main-ecs-cluster"

  tags = {
    Name = "main-ecs-cluster"
  }
}

resource "aws_ecs_capacity_provider" "asg" {
  name = "asg-orbidi-provider"

  auto_scaling_group_provider {
    auto_scaling_group_arn         = aws_autoscaling_group.ecs.arn
    managed_scaling {
      status                    = "ENABLED"
      target_capacity           = 75
      minimum_scaling_step_size = 1
      maximum_scaling_step_size = 100
    }
    managed_termination_protection = "ENABLED"
  }

  tags = {
    Name = "ecs-asg-provider"
  }
}

resource "aws_ecs_task_definition" "main" {
  family                   = "main-task"
  container_definitions    = jsonencode([
    {
      name      = "app-container"
      image     = "${data.aws_ssm_parameter.ecr_url.value}:latest"
      memory    = 256
      cpu       = 256
      essential = true
      environment = [
        {
          "name" = "DB_HOST"
          "value": aws_rds_cluster.main.endpoint
        },
        {
          "name" = "DB_USER"
          "value": aws_rds_cluster.main.master_username
        },
        {
          "name": "DB_NAME"
          "value": "test"
        },
        {
          "name": "DB_PASSWORD"
          "valueFrom": aws_ssm_parameter.rds_password.arn
        }
      ]
      portMappings = [
        {
          containerPort = 80
          hostPort      = 80
          protocol      = "tcp"
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-create-group = "true"
          awslogs-region = "us-east-1"
          awslogs-group = "/ecs/main-task"
          awslogs-stream-prefix = "ecs"
          mode = "non-blocking"
          max-buffer-size = "25m"
        }
      }
    }
  ])
  requires_compatibilities = ["EC2"]
  network_mode             = "awsvpc"
  execution_role_arn       = aws_iam_role.main.arn
  task_role_arn            = aws_iam_role.main.arn
  cpu                      = "256"
  memory                   = "256"
}

resource "aws_ecs_service" "main" {
  name            = "main-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.main.arn
  desired_count   = 2
  launch_type     = "EC2"
  force_new_deployment = true

  network_configuration {
    subnets = aws_subnet.private[*].id
    security_groups = [aws_security_group.ecs.id]
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.main.arn
    container_name   = "app-container"
    container_port   = 80
  }

  deployment_controller {
    type = "ECS"
  }
}