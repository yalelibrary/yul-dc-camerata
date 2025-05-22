check_cluster() {
  if [[ -z $1 ]]
  then
    echo "ERROR: Please supply a cluster name as your first argument"
    errors="true"
  fi
}

check_profile() {
  if [[ -z ${AWS_PROFILE} ]]
  then
    echo "ERROR: Please set an aws profile using \"export AWS_PROFILE=your_profile_name\""
    errors="true"
  fi
}

check_region() {
  if [[ -z ${AWS_DEFAULT_REGION} ]]
  then
    echo "ERROR: Please set an aws region using \"export AWS_DEFAULT_REGION=your_region\""
    errors="true"
  fi
}

check_params() {
  if [[ -z $1 ]]
  then
    errors="true" # Already covered by check_cluster, but prevents misleading error message for params
  else
    if [[ ! -f ${1}-ecs-params.yml ]]
    then
      echo "ERROR: Missing params file, please run \"bin/get-params.sh ${1}\" first"
      errors="true"
    fi
  fi
}

check_secrets() {
  if [[ ! -f .secrets ]]
  then
    echo "ERROR: Please provide a \".secrets\" file.  See the \"secrets-template\" file for an example."
    errors="true"
  fi
}

check_primary_key() {
  if [[ ${#RAILS_PRIMARY_KEY} != 32 ]]
  then
    echo "ERROR: Please ensure you have a valid 16-byte (32 hex characters) RAILS_PRIMARY_KEY set."
    errors="true"
  fi
}

check_compose() {
  if [[ -z $COMPOSE_FILE ]]
   then
    export COMPOSE_FILE=./docker-compose.yml
  fi
}

all_pass() {
  if [[ -z "$errors" ]]
  then
    return 0
  else
    return -1
  fi
}

