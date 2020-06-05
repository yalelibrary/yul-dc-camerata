#!/bin/bash
set -ex
. ./funs.sh


CLUSTER_NAME=$1


if check_name ${CLUSTER_NAME} && \ 
   check_vars AWS_PROFILE AWS_DEFAULT_REGION  && \
  check_exec 'jq' 
then
  echo "Target cluster: ${CLUSTER_NAME}"
  echo "Using AWS_PROFILE=${AWS_PROFILE}";
  echo "      AWS_DEFAULT_REGION=${AWS_DEFAULT_REGION}";
  ecs-cli up --cluster ${CLUSTER_NAME} --launch-type FARGATE --region $AWS_DEFAULT_REGION | tee cluster-ids.txt

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
  exit 1
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

  EFS_FS_ID=`aws efs create-file-system \
    --creation-token ${CLUSTER_NAME}-solr-efs \
    --performance-mode generalPurpose \
    --throughput-mode bursting \
    --region $AWS_DEFAULT_REGION \
    --tags Key=Name,Value="${CLUSTER_NAME}-solr" \
      | grep -Eo -m 1 '\"fs-\w+' | sed s/\"//`

ACCESS_POINT_ID_SOLR=`aws efs create-access-point \
  --file-system-id ${EFS_FS_ID} \
  --client-token ap-solr-1 \
  --tags Key=Name,Value="${CLUSTER_NAME}-ap-solr" \
  --root-directory Path=/efs-ap-${CLUSTER_NAME}-solr,CreationInfo=\{OwnerUid=8389,OwnerGid=8389,Permissions=755\} \
  --posix-user Uid=8389,Gid=8389 | jq .AccessPointId`

ACCESS_POINT_ID_PSQL=`aws efs create-access-point \
  --file-system-id ${EFS_FS_ID} \
  --client-token ap-psql-1 \
  --tags Key=Name,Value="${CLUSTER_NAME}-ap-solr" \
  --root-directory Path=/efs-ap-${CLUSTER_NAME}-psql,CreationInfo=\{OwnerUid=8389,OwnerGid=8389,Permissions=755\} \
  --posix-user Uid=999,Gid=999 | jq .AccessPointId`




  cat <<ECS_PARAMS > ${CLUSTER_NAME}-ecs-params.yml
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
        access_point: $ACCESS_POINT_ID_SOLR
        transit_encryption: ENABLED
        transit_encryption_port: 4182
        iam: DISABLED
      - name: "psql_efs"
        filesystem_id: $EFS_FS_ID
        access_point: $ACCESS_POINT_ID_PSQL
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
ECS_PARAMS

fi
