provider "aws" {
  region = "us-east-1" # Change this if needed
}

# 🔹 Create an ECS Cluster
resource "aws_ecs_cluster" "default_cluster" {
  name = "SoumyEcsCluster"
}

# 🔹 Secure IAM Role for ECS Task Execution
resource "aws_iam_role" "ecs_task_execution_role" {
  name = "ecsTaskExecutionRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = { Service = "ecs-tasks.amazonaws.com" }
    }]
  })
}

# 🔹 Attach IAM Policy for ECS Execution
resource "aws_iam_policy_attachment" "ecs_task_execution_role_policy" {
  name       = "ecs-task-execution-policy"
  roles      = [aws_iam_role.ecs_task_execution_role.name]
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# 🔹 Create Security Group (Allows HTTP Traffic)
resource "aws_security_group" "ecs_sg" {
  name        = "ecs-public-sg"
  description = "Allow HTTP access"
  vpc_id      = data.aws_vpc.default.id

  # Allow HTTP traffic
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# 🔹 Fetch Default VPC (No Manual Input Required)
data "aws_vpc" "default" {
  default = true
}

# 🔹 Fetch Default Subnets (Public)
data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# 🔹 ECS Task Definition (Using Secure Image)
resource "aws_ecs_task_definition" "default_task" {
  family                   = "default-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"

  execution_role_arn = aws_iam_role.ecs_task_execution_role.arn

  container_definitions = jsonencode([{
    name  = "default-container"
    image = "public.ecr.aws/nginx/nginx:latest" # Default Nginx Image
    essential = true
    memory    = 512
    cpu       = 256

    portMappings = [{
      containerPort = 80
      hostPort      = 80
    }]

    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group"         = "/ecs/default-service"
        "awslogs-region"        = "us-east-1"
        "awslogs-stream-prefix" = "ecs"
      }
    }
  }])
}

# 🔹 Create ECS Service (Using Default VPC & Public IP)
resource "aws_ecs_service" "default_service" {
  name            = "default-service"
  cluster         = aws_ecs_cluster.default_cluster.id
  task_definition = aws_ecs_task_definition.default_task.arn
  launch_type     = "FARGATE"
  desired_count   = 1

  network_configuration {
    subnets          = data.aws_subnets.default.ids
    security_groups  = [aws_security_group.ecs_sg.id]
    assign_public_ip = true
  }
}
