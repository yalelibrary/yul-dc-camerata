#!/bin/bash -e

. $(dirname "$0")/shared-checks.sh

if check_compose && check_profile && check_region && check_cluster $1 && all_pass
then
  echo "Target cluster: ${1}"
  echo "Using AWS_PROFILE=${AWS_PROFILE}";
  echo "      AWS_DEFAULT_REGION=${AWS_DEFAULT_REGION}";
  ecs-cli compose --region $AWS_DEFAULT_REGION --project-name ${1}-${2} service ps --cluster ${1}
else
  echo "\nUSAGE: bin/cluster-ps.sh \$CLUSTER_NAME \$TASK_NAME\n" # Parameters not set correctly
fi
