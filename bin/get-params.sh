#!/bin/bash -e
. $(dirname "$0")/shared-checks.sh
CLUSTER_NAME=$1

if [[ -z $2 ]]
then
  memory='4GB'
else
  memory=$2
fi

if [[ -z $3 ]]
then
  cpu='512'
else
  cpu=$3
fi


if check_profile && check_region && check_cluster $1 && all_pass
then
  echo "Using AWS_PROFILE=${AWS_PROFILE}"
  echo "      AWS_DEFAULT_REGION=${AWS_DEFAULT_REGION} \n"
  echo "      mem_limit=${memory}"
  echo "      cpu_limit=${cpu}\n"

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
      assign_public_ip: ENABLED
  service_discovery:
    container_name: solr
    private_dns_namespace:
      name: app
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
      assign_public_ip: ENABLED
  service_discovery:
    container_name: db
    private_dns_namespace:
      name: app
      vpc: $VPC_ID

ECS_PARAMS

  cat <<ECS_PARAMS > ${1}-ecs-params.yml
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
      assign_public_ip: ENABLED
  service_discovery:
    private_dns_namespace:
      name: app
      vpc: $VPC_ID
ECS_PARAMS
else
  echo "\nUSAGE: bin/cluster-ps.sh \$CLUSTER_NAME [memory] [cpu]\n" # Parameters not set correctly
fi
