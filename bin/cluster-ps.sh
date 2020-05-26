#!/bin/sh
if [[ -z $1 ]]
then
  echo "ERROR: Please supply a cluster name"
else
  cluster='ok'
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

if [[ -n ${cluster} ]] && [[ -n ${profile} ]] && [[ -n ${region} ]]
then
  echo "Target cluster: ${1}"
  echo "Using AWS_PROFILE=${AWS_PROFILE}";
  echo "      AWS_DEFAULT_REGION=${AWS_DEFAULT_REGION}";
  ecs-cli compose --region $AWS_DEFAULT_REGION --project-name ${1}-project service ps --cluster ${1}
fi

