#!/bin/bash -e

. $(dirname "$0")/shared-checks.sh
. $(dirname "$0")/efs-fun.sh
export CLUSTER_NAME=${1}

if check_profile && check_region && check_cluster $1 && all_pass
then
  echo "Target cluster: ${CLUSTER_NAME}"
  echo "Using AWS_PROFILE=${AWS_PROFILE}";
  echo "      AWS_DEFAULT_REGION=${AWS_DEFAULT_REGION}";

  if [[ ! -f ${1}-mft-params.yml ]]
  then
    export PUBLIC_IP
    $(dirname "$0")/get-params.sh ${1}
  fi

  if [[ $(aws ecs describe-services --cluster $1 --services $1-mft) = *MISSING* ]]
  then
    discovery="--enable-service-discovery"
    log="--create-log-groups"
  else
    discovery=""
    log=""
  fi

  if [ -z ${COMPOSE_FILE} ]
  then
    export COMPOSE_FILE=docker-compose.yml
  fi

  # Get MANIFEST target group ARN so we can connect the new cluster to the existing load balancer
  MFST_TG_ARN=`aws elbv2 describe-target-groups \
    --names tg-${CLUSTER_NAME}-manifests \
    --query "(TargetGroups[?TargetGroupName=='tg-${CLUSTER_NAME}-manifests'])[0].TargetGroupArn" \
      | grep -Eo "arn:aws:[^\"]+"`

  # Launch the service and register containers with the loadbalancer
  ecs-cli compose  \
    --region $AWS_DEFAULT_REGION \
    --project-name ${CLUSTER_NAME}-mft\
    --ecs-params ${CLUSTER_NAME}-mft-params.yml \
    service up \
    $2 \
    --launch-type FARGATE \
    $discovery $log \
    --force-deployment \
    --timeout 10 \
    --target-groups targetGroupArn=$MFST_TG_ARN,containerName=iiif_manifest,containerPort=80 \
    --cluster ${CLUSTER_NAME}
fi
