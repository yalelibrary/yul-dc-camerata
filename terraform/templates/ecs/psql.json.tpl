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
          "awslogs-group": "logs-${cluster_name}",
          "awslogs-region": "${aws_region}",
          "awslogs-stream-prefix": "${app}"
        }
    },
    "environment" :[
      {"name": "POSTGRES_MULTIPLE_DATABASES", "value": "blacklight_yul_production,management_yul_production"},
      {"name": "POSTGRES_HOST", "value": "db"},
      {"name": "POSTGRES_USER", "value": "postgres"},
      {"name": "POSTGRES_PASSWORD", "value": "password"}

    ],
    "mountPoints": [{
      "readOnly": false,
      "containerPath": "/var/lib/postgresql/data",
      "sourceVolume": "psql_efs"
    }],
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
