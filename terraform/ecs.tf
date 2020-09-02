# ecs.tf

resource "aws_ecs_cluster" "main" {
  name = var.cluster_name
}

data "template_file" "psql" {
  template = file("./templates/ecs/psql.json.tpl")
  vars = {
    fargate_cpu    = var.fargate_cpu
    fargate_memory = var.fargate_memory
    aws_region     = var.aws_region
    cluster_name   = var.cluster_name
    app_port       = var.app_ports.psql
    app            = "psql"
    vpc_id         = aws_vpc.main.id
    version        = var.versions.psql
  }
}


resource "aws_ecs_task_definition" "psql" {
  family                   = "${var.cluster_name}-psql"
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.fargate_cpu
  memory                   = var.fargate_memory
  container_definitions    = data.template_file.psql.rendered

  volume {
    name = "psql_efs"
    efs_volume_configuration {
      file_system_id          = aws_efs_file_system.filesystem.id
      transit_encryption      = "ENABLED"
      transit_encryption_port = "4182"
      authorization_config {
        iam             = "DISABLED"
        access_point_id = aws_efs_access_point.psql.id
      }
    }
  }
}

resource "aws_ecs_service" "psql" {
  name             = "${var.cluster_name}-psql"
  cluster          = aws_ecs_cluster.main.id
  task_definition  = aws_ecs_task_definition.psql.arn
  desired_count    = "1"
  launch_type      = "FARGATE"
  platform_version = "1.4.0"

  network_configuration {
    security_groups  = [aws_security_group.ecs_tasks.id]
    subnets          = aws_subnet.private.*.id
    assign_public_ip = false
  }
  service_registries {
    registry_arn = aws_service_discovery_service.fargate.arn
  }

  depends_on = [aws_iam_role_policy_attachment.ecs_task_execution_role]
}


resource "aws_cloudwatch_log_group" "log_group" {
  name = "logs-${var.cluster_name}"

  tags = {
    Environment = "terraform"
    Application = "ecs-${var.cluster_name}"
  }
}
