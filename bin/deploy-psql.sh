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

  if [[ ! -f ${1}-psql-params.yml ]]
  then
    export PUBLIC_IP
    $(dirname "$0")/get-params.sh ${1}
  fi

  if [[ $(aws ecs describe-services --cluster $1 --services $1-psql) = *MISSING* ]]
  then
    discovery="--enable-service-discovery"
    log="--create-log-groups"
  else
    discovery=""
    log=""
  fi

  if [ -z ${COMPOSE_FILE} ]
  then
    export COMPOSE_FILE=psql-compose.yml
  fi

  if [ -z ${discovery} ]
  then
    RUN_STATUS=`ecs-cli compose  \
            --region $AWS_DEFAULT_REGION \
            --project-name ${CLUSTER_NAME}-psql \
            service ps -c ${CLUSTER_NAME}`

    if [[ ${RUN_STATUS}] = *RUNNING* ]]
    then
      echo "Found running psql database. Please stop db before re-deploying"
      exit 1
    fi
  fi
  # Launch the service and register containers with the loadbalancer
  ecs-cli compose  \
    --region $AWS_DEFAULT_REGION \
    --project-name ${CLUSTER_NAME}-psql\
    --ecs-params ${CLUSTER_NAME}-psql-params.yml \
    service up \
    $2 \
    --launch-type FARGATE \
    $discovery $log \
    --force-deployment \
    --cluster ${CLUSTER_NAME}
fi
