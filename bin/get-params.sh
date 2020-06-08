#!/bin/sh
set -e

if [[ -z $1 ]]
then
  echo "ERROR: Please supply a cluster name"
else
  cluster='ok'
fi

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

if [[ -z ${AWS_PROFILE} ]]
then
  echo "ERROR: Please set an aws profile using \"export AWS_PROFILE=your_profile_name\"\n"
else
  profile='ok'
fi

if [[ -z ${AWS_DEFAULT_REGION} ]]
then
  echo "ERROR: Please set an aws region using \"export AWS_DEFAULT_REGION=your_region\"\n"
else
  region='ok'
fi

if [[ -n ${cluster} ]] && [[ -n ${profile} ]] && [[ -n ${region} ]]
then
  echo "Using AWS_PROFILE=${AWS_PROFILE}"
  echo "      AWS_DEFAULT_REGION=${AWS_DEFAULT_REGION} \n"
  echo "      mem_limit=${memory}"
  echo "      cpu_limit=${cpu}"

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
fi
