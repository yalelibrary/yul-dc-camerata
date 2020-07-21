#!/bin/bash -e

. $(dirname "$0")/shared-checks.sh
. $(dirname "$0")/efs-fun.sh
export CLUSTER_NAME=${1}

if check_profile && check_region && check_cluster $1 && check_secrets && all_pass
then
  echo "Target cluster: ${CLUSTER_NAME}"
  echo "Using AWS_PROFILE=${AWS_PROFILE}";
  echo "      AWS_DEFAULT_REGION=${AWS_DEFAULT_REGION}";

  if [[ ! -f ${1}-psql-params.yml ]]
  then
    bin/get-params.sh ${1}
  fi

  if [[ $(aws ecs describe-services --cluster $1 --services $1-psql) = *MISSING* ]]
  then
    discovery="--enable-service-discovery"
    log="--create-log-groups"
  else
    discovery=""
    log=""
  fi
  # Launch the service and register containers with the loadbalancer
  ecs-cli compose  \
    --region $AWS_DEFAULT_REGION \
    --project-name ${CLUSTER_NAME}-psql\
    --file psql-compose.yml \
    --ecs-params ${CLUSTER_NAME}-psql-params.yml \
    service up \
    $2 \
    --launch-type FARGATE \
    $discovery $log \
    --force-deployment \
    --cluster ${CLUSTER_NAME}
fi
