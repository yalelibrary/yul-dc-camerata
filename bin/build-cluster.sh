#!/bin/bash -ex

. $(dirname "$0")/shared-checks.sh
. $(dirname "$0")/efs-fun.sh
CLUSTER_NAME=$1
if check_profile && check_region && check_cluster $1 && all_pass
then
  echo "Target cluster: ${CLUSTER_NAME}"
  echo "Using AWS_PROFILE=${AWS_PROFILE}";
  echo "      AWS_DEFAULT_REGION=${AWS_DEFAULT_REGION}";
  ecs-cli up --force --cluster ${CLUSTER_NAME} --launch-type FARGATE --region $AWS_DEFAULT_REGION | tee cluster-ids.txt

  echo "Extracting vpc & subnet IDs"
  VPC_ID=`sed -n 's/VPC created: \(.*\)/\1/p' < cluster-ids.txt`
  SUBNET0=`grep -Eo "subnet-\w+$" cluster-ids.txt | sed -n '1p'`
  SUBNET1=`grep -Eo "subnet-\w+$" cluster-ids.txt | sed -n '2p'`
  echo "  $VPC_ID"
  echo "  $SUBNET0"
  echo "  $SUBNET1"
  echo "Setup ingress security group"
  SG_ID=`aws ec2 describe-security-groups --filters Name=vpc-id,Values=$VPC_ID --region=$AWS_DEFAULT_REGION | jq -r ".SecurityGroups[0].GroupId"`
  echo "  $SG_ID"

  create_fs $CLUSTER_NAME $AWS_DEFAULT_REGION
  put_policy
  create_mount_target $SUBNET0
  create_mount_target $SUBNET1
  create_access_point "solr" "8983" "8983" "755" 
cat <<-SOLR_PARAMS > $CLUSTER_NAME-solr-params.yml
version: 1
task_definition:
  task_execution_role: ecsTaskExecutionRole
  ecs_network_mode: awsvpc
  task_size:
    mem_limit: 8GB
    cpu_limit: 2048
  efs_volumes:
    - name: "solr_efs"
      filesystem_id: $EFS_FS_ID
      access_point: $ACCESS_POINT_ID
      transit_encryption: ENABLED
      transit_encryption_port: 4181
      iam: DISABLED
run_params:
  network_configuration:
    awsvpc_configuration:
      subnets:
        - $SUBNET0
        - $SUBNET1
      SG_IDs:
        - $SG_ID
      assign_public_ip: ENABLED
  service_discovery:
    container_name: solr
    private_dns_namespace:
      name: app
      vpc: $VPC_ID
SOLR_PARAMS

  create_access_point "psql" "999" "999" "755" 
cat <<-PSQL_PARAMS > $CLUSTER_NAME-psql-params.yml
version: 1
task_definition:
  task_execution_role: ecsTaskExecutionRole
  ecs_network_mode: awsvpc
  task_size:
    mem_limit: 8GB
    cpu_limit: 2048
  efs_volumes:
      - name: "psql_efs"
        filesystem_id: $EFS_FS_ID
        access_point: $ACCESS_POINT_ID
        transit_encryption: ENABLED
        transit_encryption_port: 4182
        iam: DISABLED
run_params:
  network_configuration:
    awsvpc_configuration:
      subnets:
        - $SUBNET0
        - $SUBNET1
      SG_IDs:
        - $SG_ID
      assign_public_ip: ENABLED
  service_discovery:
    container_name: db
    private_dns_namespace:
      name: app
      vpc: $VPC_ID
PSQL_PARAMS

cat <<ECS_PARAMS > ${CLUSTER_NAME}-ecs-params.yml
version: 1
task_definition:
  task_execution_role: ecsTaskExecutionRole
  ecs_network_mode: awsvpc
  task_size:
    mem_limit: 8GB
    cpu_limit: 2048
run_params:
  network_configuration:
    awsvpc_configuration:
      subnets:
        - $SUBNET0
        - $SUBNET1
      security_groups:
        - $SG_ID
      assign_public_ip: ENABLED
  service_discovery:
    private_dns_namespace:
      name: app
      vpc: $VPC_ID
ECS_PARAMS

fi
