#!/bin/bash -e

. ./funs.sh

CLUSTER_NAME=$1

if  check_name $CLUSTER_NAME && \
   check_vars AWS_PROFILE AWS_DEFAULT_REGION && \
   check_files '.secrets' "${CLUSTER_NAME}-ecs-params.yaml" && \
   check_exec yq \
   && check_exec 'jq';
then
  echo "Target cluster: ${CLUSTER_NAME}"
  echo "Using AWS_PROFILE=${AWS_PROFILE}";
  echo "      AWS_DEFAULT_REGION=${AWS_DEFAULT_REGION}";

  # Get BLACKLIGHT target group ARN so we can connect the new cluster to the existing load balancer
  BL_TG_ARN=`aws elbv2 describe-target-groups \
    --names tg-${CLUSTER_NAME}-blacklight \
    --query "(TargetGroups[?TargetGroupName=='tg-${CLUSTER_NAME}-blacklight'])[0].TargetGroupArn" \
      | grep -Eo "arn:aws:[^\"]+"`
  echo $BL_TG_ARN

  # Get IMAGE target group ARN so we can connect the new cluster to the existing load balancer
  IMG_TG_ARN=`aws elbv2 describe-target-groups \
    --names tg-${CLUSTER_NAME}-images \
    --query "(TargetGroups[?TargetGroupName=='tg-${CLUSTER_NAME}-images'])[0].TargetGroupArn" \
      | grep -Eo "arn:aws:[^\"]+"`
  echo $IMG_TG_ARN

  # Get MANIFEST target group ARN so we can connect the new cluster to the existing load balancer
  MFST_TG_ARN=`aws elbv2 describe-target-groups \
    --names tg-${CLUSTER_NAME}-manifests \
    --query "(TargetGroups[?TargetGroupName=='tg-${CLUSTER_NAME}-manifests'])[0].TargetGroupArn" \
      | grep -Eo "arn:aws:[^\"]+"`
  echo $MFST_TG_ARN

  # Get MANAGEMENT target group ARN so we can connect the new cluster to the existing load balancer
  MGMT_TG_ARN=`aws elbv2 describe-target-groups \
    --names tg-${CLUSTER_NAME}-management \
    --query "(TargetGroups[?TargetGroupName=='tg-${CLUSTER_NAME}-management'])[0].TargetGroupArn" \
      | grep -Eo "arn:aws:[^\"]+"`
  echo $MGMT_TG_ARN

  # Merge the docker-compose.yml and docker-compose-ecs.yml files
  # Mimics docker-compose support for multiple compsose files since
  # ecs-cli doesn't implement this functionality directly
  # see https://docs.docker.com/compose/extends/#adding-and-overriding-configuration
  yq m -x docker-compose.yml docker-compose.ecs.yml > docker-compose-merged.yml

  # Launch the service and register containers with the loadbalancer
  ecs-cli compose  \
    --region $AWS_DEFAULT_REGION \
    --project-name ${CLUSTER_NAME}-project \
    --file docker-compose-merged.yml \
    --ecs-params ${CLUSTER_NAME}-ecs-params.yml \
    service up \
    --create-log-groups \
    --cluster ${CLUSTER_NAME} \
    --target-groups targetGroupArn=$BL_TG_ARN,containerName=blacklight,containerPort=3000 \
    --target-groups targetGroupArn=$IMG_TG_ARN,containerName=iiif_image,containerPort=8182 \
    --target-groups targetGroupArn=$MFST_TG_ARN,containerName=iiif_manifest,containerPort=80 \
    --target-groups targetGroupArn=$MGMT_TG_ARN,containerName=management,containerPort=3001
fi
