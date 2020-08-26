[
  {
    "name": "${cluster_name}-${app}",
    "image": "yalelibraryit/dc-postgres:${version}",
    "cpu": ${fargate_cpu},
    "memory": ${fargate_memory},
    "networkMode": "awsvpc",
    "logConfiguration": {
        "logDriver": "awslogs",
        "options": {
          "awslogs-group": "${cluster_name}/ecs/${cluster_name}-${app}",
          "awslogs-region": "${aws_region}",
          "awslogs-stream-prefix": "${app}"
        }
    },
    "portMappings": [
      {
        "containerPort": ${app_port},
        "hostPort": ${app_port}
      }
    ],
    "runParams": {
      "serviceDiscovery": {
        "privateDnsNamespace": {
          "name": "${cluster_name}",
          "vpc": "${vpc_id}"
        }
      }
    }
  }
]
