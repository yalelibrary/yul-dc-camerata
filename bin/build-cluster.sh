#!/bin/bash -e

. $(dirname "$0")/shared-checks.sh

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


  EFS_FS_ID=`aws efs create-file-system \
    --creation-token ${CLUSTER_NAME}-solr-efs \
    --performance-mode generalPurpose \
    --throughput-mode bursting \
    --region $AWS_DEFAULT_REGION \
    --tags Key=Name,Value="${CLUSTER_NAME}-solr" \
      | grep -Eo -m 1 '\"fs-\w+' | sed s/\"//`

  sleep 30 #allow time for the filesystem to come online

  aws efs put-file-system-policy --file-system-id $EFS_FS_ID  --policy '{
    "Version": "2012-10-17",
    "Id": "allorw",
    "Statement": [
        {
            "Sid": "AllowRW",
            "Effect": "Allow",
            "Principal": {
                "AWS": "*"
            },
            "Action": [
                "elasticfilesystem:ClientMount",
                "elasticfilesystem:ClientWrite"
            ]
        }
    ]
}'


ACCESS_POINT_ID_SOLR=`aws efs create-access-point \
  --file-system-id ${EFS_FS_ID} \
  --client-token ${CLUSTER_NAME}-ap-solr-1 \
  --tags Key=Name,Value="${CLUSTER_NAME}-ap-solr" \
  --root-directory Path=/efs-ap-${CLUSTER_NAME}-solr,CreationInfo=\{OwnerUid=8983,OwnerGid=8983,Permissions=755\} \
  --posix-user Uid=8983,Gid=8983 | jq .AccessPointId`

ACCESS_POINT_ID_PSQL=`aws efs create-access-point \
  --file-system-id ${EFS_FS_ID} \
  --client-token ${CLUSTER_NAME}-ap-psql-1 \
  --tags Key=Name,Value="${CLUSTER_NAME}-ap-psql" \
  --root-directory Path=/efs-ap-${CLUSTER_NAME}-psql,CreationInfo=\{OwnerUid=999,OwnerGid=999,Permissions=755\} \
  --posix-user Uid=999,Gid=999 | jq .AccessPointId`

echo "creating mount targets"
aws efs create-mount-target \
--file-system-id $EFS_FS_ID \
--subnet-id  $SUBNET0

aws efs create-mount-target \
--file-system-id $EFS_FS_ID \
--subnet-id  $SUBNET1

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
        transit_encryption_port: 4181
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
