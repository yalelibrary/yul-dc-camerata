#!/bin/bash
set -e

. $(dirname "$0")/shared-checks.sh
. $(dirname "$0")/efs-fun.sh
export CLUSTER_NAME=${1}

if check_profile && check_region && check_cluster $1 && all_pass
then
  echo "Target cluster: ${CLUSTER_NAME}"
  echo "Using AWS_PROFILE=${AWS_PROFILE}";
  echo "      AWS_DEFAULT_REGION=${AWS_DEFAULT_REGION}";

  if [[ ! -f ${1}-blacklight-params.yml ]]
  then
    export PUBLIC_IP
    $(dirname "$0")/get-params.sh ${1}
  fi

  if [[ $(aws ecs describe-services --cluster $1 --services $1-blacklight) = *MISSING* ]]
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

  BL_TG_ARN=`aws elbv2 describe-target-groups \
    --names tg-${CLUSTER_NAME}-blacklight \
    --query "(TargetGroups[?TargetGroupName=='tg-${CLUSTER_NAME}-blacklight'])[0].TargetGroupArn" \
      | grep -Eo "arn:aws:[^\"]+"`

  ecs-cli compose  \
    --region $AWS_DEFAULT_REGION \
    --project-name ${CLUSTER_NAME}-blacklight \
    --ecs-params ${CLUSTER_NAME}-blacklight-params.yml \
    service up \
    $2 \
    --launch-type FARGATE \
    $discovery $log \
    --force-deployment \
    --create-log-groups \
    --target-groups targetGroupArn=$BL_TG_ARN,containerName=blacklight,containerPort=3000 \
    --timeout 10 \
    --cluster ${CLUSTER_NAME} \
    --tags Application=DigitalCollection
fi
