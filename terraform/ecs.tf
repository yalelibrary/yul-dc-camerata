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
    images         = var.images["psql"]
    ports          = var.app_ports["psql"]
    app            = "psql"
    vpc_id         = aws_vpc.main.id
  }
}

data "template_file" "solr" {
  template = file("./templates/ecs/solr.json.tpl")
  vars = {
    fargate_cpu    = var.fargate_cpu
    fargate_memory = var.fargate_memory
    aws_region     = var.aws_region
    cluster_name   = var.cluster_name
    images         = var.images["solr"]
    ports          = var.app_ports["solr"]
    app            = "solr"
    vpc_id         = aws_vpc.main.id
  }
}
data "template_file" "main" {
  template = file("./templates/ecs/main.json.tpl")
  vars = {
    fargate_cpu    = var.fargate_cpu
    fargate_memory = var.fargate_memory
    aws_region     = var.aws_region
    cluster_name   = var.cluster_name
    images         = var.images.psql
    ports          = var.app_ports.psql
    app            = "main"
    vpc_id         = aws_vpc.main.id
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
}
resource "aws_ecs_task_definition" "solr" {
  family                   = "${var.cluster_name}-solr"
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.fargate_cpu
  memory                   = var.fargate_memory
  container_definitions    = data.template_file.solr.rendered
}
resource "aws_ecs_task_definition" "main" {
  family                   = "${var.cluster_name}-main"
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.fargate_cpu
  memory                   = var.fargate_memory
  container_definitions    = data.template_file.main.rendered
}

resource "aws_ecs_service" "main" {
  name            = "${var.cluster_name}-main"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.main.arn
  desired_count   = var.app_count
  launch_type     = "FARGATE"

  network_configuration {
    security_groups  = [aws_security_group.ecs_tasks.id]
    subnets          = aws_subnet.private.*.id
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_alb_target_group.mft.arn
    container_name   = "iiif_image"
    container_port   = var.app_ports["image"]
  }
  load_balancer {
    target_group_arn = aws_alb_target_group.mft.arn
    container_name   = "iiif_manifest"
    container_port   = var.app_ports["mft"]
  }
  load_balancer {
    target_group_arn = aws_alb_target_group.mgmt.arn
    container_name   = "management"
    container_port   = var.app_ports["mgmt"]
  }
  load_balancer {
    target_group_arn = aws_alb_target_group.blacklight.arn
    container_name   = "blacklight"
    container_port   = var.app_ports["blacklight"]
  }

  depends_on = [aws_alb_listener.http, aws_alb_listener.https, aws_iam_role_policy_attachment.ecs_task_execution_role]
}

