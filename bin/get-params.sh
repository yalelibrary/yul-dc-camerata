#!/bin/bash
set -e
. $(dirname "$0")/shared-checks.sh
CLUSTER_NAME=$1
echo "Using cluster name=${CLUSTER_NAME}"


if [[ -z $2 ]]
then
  memory='16384'
else
  memory=$2
fi

if [[ -z $3 ]]
then
  cpu='2048'
else
  cpu=$3
fi
PUBLIC_IP=${PUBLIC_IP:-DISABLED}
echo "Using public ip =${PUBLIC_IP}"
echo "Using VPC id=${VPC_ID}"

if check_profile && check_region && check_cluster $1 && all_pass
then
  echo "Using AWS_PROFILE=${AWS_PROFILE}"
  echo "      AWS_DEFAULT_REGION=${AWS_DEFAULT_REGION} \n"
  echo "      mem_limit=${memory}"
  echo "      cpu_limit=${cpu}\n"

  if [ "$VPC_ID" ]
  then
    if [ -z "$SUBNET0" ] | [ -z "$SUBNET1" ]
    then
      echo "If using VPC set SUBNET0 and SUBNET1..."
      exit 1
    fi
    SG_ID=`aws ec2 describe-security-groups \
      --filters Name=vpc-id,Values=$VPC_ID \
      --query "(SecurityGroups[?GroupName=='${CLUSTER_NAME}-sg'])[0].GroupId" `
  else
    NOTYALE=1
  fi

  if [ "$NOTYALE" = "1" ]
  then
    SUBNET0=`aws cloudformation list-stack-resources \
      --stack-name amazon-ecs-cli-setup-${1} \
        --query "(StackResourceSummaries[?LogicalResourceId=='PubSubnetAz1'].PhysicalResourceId)[0]"`
    SUBNET1=`aws cloudformation list-stack-resources \
      --stack-name amazon-ecs-cli-setup-${1} \
        --query "(StackResourceSummaries[?LogicalResourceId=='PubSubnetAz2'].PhysicalResourceId)[0]"`
    VPC_ID=`aws cloudformation list-stack-resources \
      --stack-name amazon-ecs-cli-setup-${1} \
          --query "(StackResourceSummaries[?LogicalResourceId=='Vpc'].PhysicalResourceId)[0]"`
    SG_ID=`aws ec2 describe-security-groups \
      --filters Name=vpc-id,Values=$VPC_ID \
      --query "(SecurityGroups[?GroupName=='default'])[0].GroupId" `
  fi

  FS_ID=`aws efs describe-file-systems --region $AWS_DEFAULT_REGION  |  jq ".FileSystems[]|select(.Tags[].Value == \"${1}-efs\").FileSystemId"`
  AP_SQL=`aws efs describe-access-points --region $AWS_DEFAULT_REGION | jq ".AccessPoints[]|select(.ClientToken==\"${1}-ap-psql-1\").AccessPointId"`
  AP_SOLR=`aws efs describe-access-points --region $AWS_DEFAULT_REGION | jq ".AccessPoints[]|select(.ClientToken==\"${1}-ap-solr-1\").AccessPointId"`
  echo $FS_ID
  echo $AP_SQL
  echo $AP_SOLR
  echo $SUBNET0
  echo $SUBNET1
  echo $SG_ID
  echo $VPC_ID

  cat <<ECS_PARAMS > ${1}-solr-params.yml
version: 1
task_definition:
  task_execution_role: ecsTaskExecutionRole
  ecs_network_mode: awsvpc
  task_size:
    mem_limit: $memory
    cpu_limit: $cpu
  efs_volumes:
      - name: "solr_efs"
        filesystem_id: $FS_ID
        access_point: $AP_SOLR
        transit_encryption: ENABLED
        transit_encryption_port: 4181
        iam: DISABLED
run_params:
  network_configuration:
    awsvpc_configuration:
      subnets:
        - $SUBNET0
        - $SUBNET1
      security_groups:
        - $SG_ID
      assign_public_ip: $PUBLIC_IP
  service_discovery:
    container_name: solr
    private_dns_namespace:
      name: $CLUSTER_NAME
      vpc: $VPC_ID

ECS_PARAMS
  cat <<ECS_PARAMS > ${1}-psql-params.yml
version: 1
task_definition:
  task_execution_role: ecsTaskExecutionRole
  ecs_network_mode: awsvpc
  task_size:
    mem_limit: $memory
    cpu_limit: $cpu
  efs_volumes:
      - name: "psql_efs"
        filesystem_id: $FS_ID
        access_point: $AP_SQL
        transit_encryption: ENABLED
        transit_encryption_port: 4181
        iam: DISABLED
run_params:
  network_configuration:
    awsvpc_configuration:
      subnets:
        - $SUBNET0
        - $SUBNET1
      security_groups:
        - $SG_ID
      assign_public_ip: $PUBLIC_IP
  service_discovery:
    container_name: db
    private_dns_namespace:
      name: $CLUSTER_NAME
      vpc: $VPC_ID

ECS_PARAMS

  cat <<ECS_PARAMS > ${1}-mgmt-params.yml
version: 1
task_definition:
  task_execution_role: ecsTaskExecutionRole
  ecs_network_mode: awsvpc
  task_size:
    mem_limit: $memory
    cpu_limit: $cpu
run_params:
  network_configuration:
    awsvpc_configuration:
      subnets:
        - $SUBNET0
        - $SUBNET1
      security_groups:
        - $SG_ID
      assign_public_ip: $PUBLIC_IP
  service_discovery:
    private_dns_namespace:
      name: $CLUSTER_NAME
      vpc: $VPC_ID
ECS_PARAMS

  cat <<ECS_PARAMS > ${1}-blacklight-params.yml
version: 1
task_definition:
  task_execution_role: ecsTaskExecutionRole
  ecs_network_mode: awsvpc
  task_size:
    mem_limit: $memory
    cpu_limit: $cpu
run_params:
  network_configuration:
    awsvpc_configuration:
      subnets:
        - $SUBNET0
        - $SUBNET1
      security_groups:
        - $SG_ID
      assign_public_ip: $PUBLIC_IP
  service_discovery:
    private_dns_namespace:
      name: $CLUSTER_NAME
      vpc: $VPC_ID
ECS_PARAMS

  cat <<ECS_PARAMS > ${1}-intensive-params.yml
version: 1
task_definition:
  task_execution_role: ecsTaskExecutionRole
  ecs_network_mode: awsvpc
  task_size:
    mem_limit: 8192
    cpu_limit: 4096
run_params:
  network_configuration:
    awsvpc_configuration:
      subnets:
        - $SUBNET0
        - $SUBNET1
      security_groups:
        - $SG_ID
      assign_public_ip: $PUBLIC_IP
  service_discovery:
    private_dns_namespace:
      name: $CLUSTER_NAME
      vpc: $VPC_ID
ECS_PARAMS

  cat <<ECS_PARAMS > ${1}-iiif-images-params.yml
version: 1
task_definition:
  task_execution_role: ecsTaskExecutionRole
  ecs_network_mode: awsvpc
  task_size:
    mem_limit: 8192
    cpu_limit: 4096
run_params:
  network_configuration:
    awsvpc_configuration:
      subnets:
        - $SUBNET0
        - $SUBNET1
      security_groups:
        - $SG_ID
      assign_public_ip: $PUBLIC_IP
  service_discovery:
    private_dns_namespace:
      name: $CLUSTER_NAME
      vpc: $VPC_ID
ECS_PARAMS

  cat <<WORKER_PARAMS > ${1}-worker-params.yml
version: 1
task_definition:
  task_execution_role: ecsTaskExecutionRole
  ecs_network_mode: awsvpc
  task_size:
    mem_limit: 12288
    cpu_limit: 4096
run_params:
  network_configuration:
    awsvpc_configuration:
      subnets:
        - $SUBNET0
        - $SUBNET1
      security_groups:
        - $SG_ID
      assign_public_ip: $PUBLIC_IP
  service_discovery:
    private_dns_namespace:
      name: $CLUSTER_NAME
      vpc: $VPC_ID
WORKER_PARAMS

else
  echo "\nUSAGE: bin/cluster-ps.sh \$CLUSTER_NAME [memory] [cpu]\n" # Parameters not set correctly
fi
