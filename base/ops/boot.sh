#!/bin/bash -e
#This script is run by /sbin/my_init at boot time
#this replaces the string @@image_url@@ in the webapp config with the value of $IIIF_IMAGE_BASE_URL
#before nginx starts
sed -i "s]@@image_url@@]${IIIF_IMAGE_BASE_URL}]g" /etc/nginx/sites-enabled/webapp.conf
if [ ! -z "$DYNATRACE_TOKEN" ];then

  curl -Ls -H "Authorization: Api-Token ${DYNATRACE_TOKEN}" 'https://nhd42358.live.dynatrace.com/api/v1/deployment/installer/agent/unix/default/latest?arch=x86&flavor=default' > installer.sh && \
  /bin/sh installer.sh  --set-app-log-content-access=true --set-infra-only=true --set-host-group=DC --set-host-name=${CLUSTER_NAME}-${TYPE} NON_ROOT_MODE=0 &
fi
