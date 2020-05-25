#!/bin/sh
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
  ecs-cli compose  --region $AWS_DEFAULT_REGION --project-name ${1}-project --file docker-compose.yml --ecs-params ${1}-ecs-params.yml service up --create-log-groups --cluster ${1}
fi
