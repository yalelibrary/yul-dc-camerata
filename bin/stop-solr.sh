#!/bin/bash -e

. $(dirname "$0")/shared-checks.sh
. $(dirname "$0")/efs-fun.sh
export CLUSTER_NAME=${1}

if check_profile && check_region && check_cluster $1 && all_pass
then
  echo "Target cluster: ${CLUSTER_NAME}"
  echo "Using AWS_PROFILE=${AWS_PROFILE}";
  echo "      AWS_DEFAULT_REGION=${AWS_DEFAULT_REGION}";
  ecs-cli compose  \
        --region $AWS_DEFAULT_REGION \
        --project-name ${CLUSTER_NAME}-solr \
        service stop -c ${CLUSTER_NAME}
fi
