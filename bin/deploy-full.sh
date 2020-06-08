#!/bin/sh
set -e

if [[ -z $1 ]]
then
  echo "ERROR: Please supply a cluster name"
else
  if [[ -f ${1}-ecs-params.yml ]]
  then
    cluster='ok'
  else
    echo "ERROR: Missing params file, please run \"bin/get-params.sh ${1}\" first"
  fi
fi

if [[ -f .secrets ]]
then
  secrets='ok'
else
  echo "ERROR: Please provide a \".secrets.yml\" file.  See \"secrets-template.yml\" for an example."
fi

if [[ -z ${AWS_PROFILE} ]]
then
  echo "ERROR: Please set an aws profile using \"export AWS_PROFILE=your_profile_name\"\n"
else
  profile='ok'
fi

if [[ -z ${AWS_DEFAULT_REGION} ]]
then
  echo "ERROR: Please set an aws region using \"export AWS_DEFAULT_REGION=your_region\"\n"
else
  region='ok'
fi


if [[ -n ${cluster} ]] && [[ -n ${profile} ]] && [[ -n ${region} ]] && [[ -n ${secrets} ]]
then
  echo "Target cluster: ${1}"
  export CLUSTER_NAME=${1}
  echo "Using AWS_PROFILE=${AWS_PROFILE}";
  echo "      AWS_DEFAULT_REGION=${AWS_DEFAULT_REGION}";

  # Get BLACKLIGHT target group ARN so we can connect the new cluster to the existing load balancer
  BL_TG_ARN=`aws elbv2 describe-target-groups \
    --names tg-${1}-blacklight \
    --query "(TargetGroups[?TargetGroupName=='tg-${1}-blacklight'])[0].TargetGroupArn" \
      | grep -Eo "arn:aws:[^\"]+"`
  echo $BL_TG_ARN

  # Get IMAGE target group ARN so we can connect the new cluster to the existing load balancer
  IMG_TG_ARN=`aws elbv2 describe-target-groups \
    --names tg-${1}-images \
    --query "(TargetGroups[?TargetGroupName=='tg-${1}-images'])[0].TargetGroupArn" \
      | grep -Eo "arn:aws:[^\"]+"`
  echo $IMG_TG_ARN

  # Get MANIFEST target group ARN so we can connect the new cluster to the existing load balancer
  MFST_TG_ARN=`aws elbv2 describe-target-groups \
    --names tg-${1}-manifests \
    --query "(TargetGroups[?TargetGroupName=='tg-${1}-manifests'])[0].TargetGroupArn" \
      | grep -Eo "arn:aws:[^\"]+"`
  echo $MFST_TG_ARN

  # Get MANAGEMENT target group ARN so we can connect the new cluster to the existing load balancer
  MGMT_TG_ARN=`aws elbv2 describe-target-groups \
    --names tg-${1}-management \
    --query "(TargetGroups[?TargetGroupName=='tg-${1}-management'])[0].TargetGroupArn" \
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
    --project-name ${1}-project \
    --file docker-compose-merged.yml \
    --ecs-params ${1}-ecs-params.yml \
    service up \
    --create-log-groups \
    --cluster ${1} \
    --target-groups targetGroupArn=$BL_TG_ARN,containerName=blacklight,containerPort=3000 \
    --target-groups targetGroupArn=$IMG_TG_ARN,containerName=iiif_image,containerPort=8182 \
    --target-groups targetGroupArn=$MFST_TG_ARN,containerName=iiif_manifest,containerPort=80 \
    --target-groups targetGroupArn=$MGMT_TG_ARN,containerName=management,containerPort=3001
fi
