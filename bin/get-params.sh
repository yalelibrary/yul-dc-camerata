#!/bin/sh
if [[ -z $1 ]]
then
  echo "ERROR: Please supply a cluster name"
else
  cluster='ok'
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
  
  export SUBNET0=`aws ecs describe-services --cluster $1 --services ${1}-project \
    --query 'services[0].deployments[0].networkConfiguration.awsvpcConfiguration.subnets[0]' \
      | sed -e 's/^"//' -e 's/"$//' `
  export SUBNET1=`aws ecs describe-services --cluster $1 --services ${1}-project \
    --query 'services[0].deployments[0].networkConfiguration.awsvpcConfiguration.subnets[1]' \
      | sed -e 's/^"//' -e 's/"$//' `
  export VPC_ID=`aws ec2 describe-subnets --subnet-ids $SUBNET0 \
    --query 'Subnets[0].VpcId' \
      | sed -e 's/^"//' -e 's/"$//' `
  export SG_ID=`aws ec2 describe-security-groups --filters \
    Name=vpc-id,Values=$VPC_ID --region=$AWS_DEFAULT_REGION | grep -Eo -m 1 'sg-\w+'`
  
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
    mem_limit: 4GB
    cpu_limit: 512
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

