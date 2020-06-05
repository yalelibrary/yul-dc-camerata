#!/bin/bash -e
CLUSTER_NAME='yale-persistence'
EFS_FS_ID='fs-55dd5cd6'

. funs.sh
check_vars AWS_PROFILE DARP AWS_DEFAULT_REGION DERP
echo $?
