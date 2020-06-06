#!/bin/bash -e

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
  echo "Target cluster: ${1}"
  echo "Using AWS_PROFILE=${AWS_PROFILE}";
  echo "      AWS_DEFAULT_REGION=${AWS_DEFAULT_REGION}";
#  ecs-cli compose --project-name ${1}-project --file docker-compose-simple.yml --ecs-params ${1}-ecs-params.yml service up --cluster ${1}
  ecs-cli up --cluster ${1} --launch-type FARGATE --region $AWS_DEFAULT_REGION | tee cluster-ids.txt

  echo "Extracting vpc & subnet IDs"
  VPC_ID=`sed -n 's/VPC created: \(.*\)/\1/p' < cluster-ids.txt`
  SUBNET0=`grep -Eo "subnet-\w+$" cluster-ids.txt | sed -n '1p'`
  SUBNET1=`grep -Eo "subnet-\w+$" cluster-ids.txt | sed -n '2p'`
  echo "  $VPC_ID"
  echo "  $SUBNET0"
  echo "  $SUBNET1"

  echo "Setup ingress security group"
  SG_ID=`aws ec2 describe-security-groups --filters \
    Name=vpc-id,Values=$VPC_ID --region=$AWS_DEFAULT_REGION | grep -Eo -m 1 'sg-\w+'`
  echo "  $SG_ID"
  aws ec2 authorize-security-group-ingress --group-id $SG_ID \
    --protocol tcp --port 80 \
    --cidr 0.0.0.0/0 \
    --region=$AWS_DEFAULT_REGION
  aws ec2 authorize-security-group-ingress --group-id $SG_ID \
    --protocol tcp --port 3000 \
    --cidr 0.0.0.0/0 \
    --region=$AWS_DEFAULT_REGION
  aws ec2 authorize-security-group-ingress --group-id $SG_ID \
    --protocol tcp --port 8983 \
    --cidr 0.0.0.0/0 \
    --region=$AWS_DEFAULT_REGION
  aws ec2 authorize-security-group-ingress --group-id $SG_ID \
    --protocol tcp --port 8182 \
    --cidr 0.0.0.0/0 \
    --region=$AWS_DEFAULT_REGION

  aws ec2 authorize-security-group-ingress --group-id $SG_ID \
    --protocol tcp --port 3001 \
    --cidr 0.0.0.0/0 \
    --region=$AWS_DEFAULT_REGION

  SOLR_FS_ID=`aws efs create-file-system \
    --creation-token ${1}-solr-efs \
    --performance-mode generalPurpose \
    --throughput-mode bursting \
    --region $AWS_DEFAULT_REGION \
    --tags Key=Name,Value="${1}-solr" \
      | grep -Eo -m 1 '\"fs-\w+' | sed s/\"//`


  cat <<ECS_PARAMS > ${1}-ecs-params.yml
version: 1
task_definition:
  task_execution_role: ecsTaskExecutionRole
  ecs_network_mode: awsvpc
  task_size:
    mem_limit: 8GB
    cpu_limit: 2048
  efs_volumes:
      - name: "solr_efs"
        filesystem_id: $SOLR_FS_ID
        root_directory: /
        transit_encryption: DISABLED
        iam: DISABLE
run_params:
  network_configuration:
    awsvpc_configuration:
      subnets:
        - $SUBNET0
        - $SUBNET1
      SG_IDs:
        - $SG_ID
      assign_public_ip: ENABLED
ECS_PARAMS

fi
