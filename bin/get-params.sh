#!/bin/sh
set -e

. $(dirname "$0")/shared-checks.sh

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

  echo $SUBNET0
  echo $SUBNET1
  echo $SG_ID
  echo $VPC_ID

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
ECS_PARAMS
else
  echo "\nUSAGE: bin/cluster-ps.sh \$CLUSTER_NAME [memory] [cpu]\n" # Parameters not set correctly
fi
