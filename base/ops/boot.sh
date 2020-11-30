#!/bin/bash -e
#This script is run by /etc/my_init at boot time
if [ ! -z "$DYNATRACE_TOKEN" ];then

  curl -Ls -H "Authorization: Api-Token ${DYNATRACE_TOKEN}" 'https://nhd42358.live.dynatrace.com/api/v1/deployment/installer/agent/unix/default/latest?arch=x86&flavor=default' > installer.sh && \
  /bin/sh installer.sh  --set-app-log-content-access=true --set-infra-only=true --set-host-group=DC --set-host-name=${CLUSTER_NAME}-blacklight NON_ROOT_MODE=0 &
fi
