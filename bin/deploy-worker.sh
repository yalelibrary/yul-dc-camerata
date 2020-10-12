#!/bin/bash -e

. $(dirname "$0")/shared-checks.sh
. $(dirname "$0")/efs-fun.sh
export CLUSTER_NAME=${1}

if check_profile && check_region && check_cluster $1 && all_pass
then
  echo "Target cluster: ${CLUSTER_NAME}"
  echo "Using AWS_PROFILE=${AWS_PROFILE}";
  echo "      AWS_DEFAULT_REGION=${AWS_DEFAULT_REGION}";

  if [[ ! -f ${1}-ecs-params.yml ]]
  then
    export PUBLIC_IP
    $(dirname "$0")/get-params.sh ${1}
  fi

  if [[ $(aws ecs describe-services --cluster $1 --services $1-worker) = *MISSING* ]]
  then
    discovery="--enable-service-discovery"
    log="--create-log-groups"
  else
    discovery=""
    log=""
  fi

  if [ -z ${COMPOSE_FILE} ]
  then
    export COMPOSE_FILE=worker-compose.yml
  fi

  ecs-cli compose  \
    --region $AWS_DEFAULT_REGION \
    --project-name ${CLUSTER_NAME}-worker \
    --ecs-params ${CLUSTER_NAME}-worker-params.yml \
    service up --launch-type EC2 \
    $2 \
    $discovery $log \
    --force-deployment \
    --cluster ${CLUSTER_NAME}
fi
