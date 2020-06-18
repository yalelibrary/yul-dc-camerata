# cluster name, region
create_fs(){
  EFS_FS_ID=`aws efs create-file-system \
    --creation-token ${1}-solr-efs \
    --performance-mode generalPurpose \
    --throughput-mode bursting \
    --region $2 \
    --tags Key=Name,Value="${1}-efs"| jq -r .FileSystemId`

  sleep 30 #allow time for the filesystem to come online
  return 0
}

put_policy() {
  aws efs put-file-system-policy --file-system-id $EFS_FS_ID  --policy '{
    "Version": "2012-10-17",
    "Id": "allorw",
    "Statement": [
        {
            "Sid": "AllowRW",
            "Effect": "Allow",
            "Principal": {
                "AWS": "*"
            },
            "Action": [
                "elasticfilesystem:ClientMount",
                "elasticfilesystem:ClientWrite"
            ]
        }
    ]
}'

}

create_mount_target() {
  aws efs create-mount-target \
  --file-system-id $EFS_FS_ID \
  --subnet-id  $1
}

# app name, owner id, group id, permissions
create_access_point() {
  ACCESS_POINT_ID=`aws efs create-access-point \
    --file-system-id ${EFS_FS_ID} \
    --client-token ${CLUSTER_NAME}-ap-${1}-1 \
    --tags Key=Name,Value="${1}-ap-$1" \
    --root-directory Path=/efs-ap-${CLUSTER_NAME}-$1,CreationInfo=\{OwnerUid=$2,OwnerGid=$3,Permissions=$4\} \
    --posix-user Uid=$2,Gid=$3 | jq -r .AccessPointId`
  return 0
}


