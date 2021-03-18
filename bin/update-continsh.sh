#!/bin/bash -e
. $(dirname "$0")/shared-checks.sh
. $(dirname "$0")/efs-fun.sh

if check_profile && check_region && check_cluster $1 && all_pass ; then
CLUSTER_NAME=$1
  # Policy doc, in case we need it
  ROLEDOC='{
    "Version": "2008-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Principal": {
          "Service": "ec2.amazonaws.com"
        },
        "Action": "sts:AssumeRole"
      }
    ]
  }'

  function create_role {
    aws iam create-role --role-name ecsInstanceRole \
    --assume-role-policy-document "$ROLEDOC" \
    --query 'Role.Arn' \
    --output text && aws iam attach-role-policy \
    --policy-arn arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role \
    --role-name ecsInstanceRole

    aws iam create-instance-profile \
    --instance-profile-name ecsInstanceProfileRole &&
    aws iam add-role-to-instance-profile \
    --instance-profile-name ecsInstanceProfileRole \
    --role-name ecsInstanceRole && check_role
    AWS_IAM_INSTANCE_PROFILE_ARN=$(aws iam list-instance-profiles-for-role \
    --role-name ecsInstanceRole \
    --query 'InstanceProfiles[0].Arn' \
    --output text)
  }

  #fetches role arn into variable, or else creates it and fetches it into a variable
  #could probably just call check role from inside create role, but this way lies madness.
  function check_role {
    AWS_IAM_INSTANCE_PROFILE_ARN=$(aws iam list-instance-profiles-for-role \
    --role-name ecsInstanceRole \
    --query 'InstanceProfiles[0].Arn' \
    --output text) || create_role
  }

  #create a keypair, store it in a file named after the cluster. Don't lose this keypair, or you'll
  #have to delete the kp already defined & recreate all the ec2 instances (not the end of the world,
  #but annoying)
  function create_key {
    aws ec2 create-key-pair --key-name $CLUSTER_NAME-keypair  --query 'KeyMaterial' \
      --output text > $CLUSTER_NAME-keypair.pem && chmod 400 $CLUSTER_NAME-keypair.pem
  }


  check_role

  #bail out here if we haven't found the instance profile arn yet
  if [ -z "${AWS_IAM_INSTANCE_PROFILE_ARN}" ];then
    echo "Could not obtain instance profile."
    exit 1
  fi


  #use latest & greatest amazon-recommended AMI
  AWS_AMI_ID=$(aws ssm get-parameters --names '/aws/service/ecs/optimized-ami/amazon-linux-2/recommended/image_id' \
    --query 'Parameters[0].Value' --output text)

  # echo $AWS_AMI_ID
  #bail if we can't find the latest AMI
  if [ -z "${AWS_AMI_ID}" ] ; then
    echo "Could not retrieve latest AMI"
    exit 1
  fi


  #create new keypair if not found. all cluster ec2 hosts will have same keypair
  aws ec2 describe-key-pairs --key-names $CLUSTER_NAME-keypair > /dev/null ||  create_key

  #gaffle the  subnet & sg from the existing ecs-params file. change the index here if you want to use some other one
  #or rearrange/update the params file (probably easier)
  AWS_SUBNET_PRIVATE_IDS=$(yq r $CLUSTER_NAME-worker-params.yml 'run_params.network_configuration.awsvpc_configuration.subnets' | awk 'BEGIN {RS=","}{print $2,$4}'| sed 's/\s/,/g')
  AWS_CUSTOM_SECURITY_GROUP_ID=$(yq r $CLUSTER_NAME-worker-params.yml 'run_params.network_configuration.awsvpc_configuration.security_groups[0]')


  #the instance boot script. runs as root. /etc/ecs/ecs.config registers
  #this instance with the cluster. should work as long as the instance
  #lives in the same vpc as the cluster
  #we are also mounting storage@yale nfs mounts
  #be cautious to escape shell significant characters, to avoid double
  #interpretation problems
  #this should probalby not hardcode stuff like hostnames some day
  #NB. this is limited to 16kb before encoding
  #NB. the macos base64 not have the w0 flag hence the b6arg nonsense.
  B6ARG='-w0'
  if [[ $OSTYPE=="darwin"* ]];then
    B6ARG=''
  fi
  USERDATA=$(echo "#!/bin/bash
  echo ECS_CLUSTER=$CLUSTER_NAME >> /etc/ecs/ecs.config && yum update -y

  # Install Dynatrace OneAgent client
  yum install -y wget
  wget -O Dynatrace-OneAgent-Linux-1.201.129.sh \
    \"https://nhd42358.live.dynatrace.com/api/v1/deployment/installer/agent/unix/default/latest?arch=x86&flavor=default\" \
    --header=\"Authorization: Api-Token ${DYNATRACE_TOKEN}\"
  /bin/sh Dynatrace-OneAgent-Linux-1.201.129.sh --set-app-log-content-access=true --set-infra-only=true --set-host-group=DC --set-host-name=${CLUSTER_NAME}-worker

  # NFS mount Goobi Hot Folders
  mkdir -p /brbl-dsu/jss_export
  mkdir -p /brbl-dsu/dcs
  if [ $CLUSTER_NAME == "yul-dc-test" ] || [ $CLUSTER_NAME == "yul-dc-infra" ]
  then
    GOOBI_HOT="wcsfs00.its.yale.internal:/NFS_SFS_std_sngl_003/Goobi_Deposits-CC1741-BRBLDSU"
    mount -t nfs -orw,nolock,rsize=32768,wsize=32768,intr,noatime,nfsvers=3 \$GOOBI_HOT/jss_export /brbl-dsu/jss_export
    mount -t nfs -orw,nolock,rsize=32768,wsize=32768,intr,noatime,nfsvers=3 \$GOOBI_HOT/dcs /brbl-dsu/dcs
  elif [ $CLUSTER_NAME == "yul-dc-uat" ] || [ $CLUSTER_NAME == "yul-dc-demo" ]
  then
    GOOBI_HOT="wcsfs00.its.yale.internal:/NFS_SFS_std_mult_000/Goobi_Deposits_UAT-CC1741-BRBLDSU"
    mount -t nfs -orw,nolock,rsize=32768,wsize=32768,intr,noatime,nfsvers=3 \$GOOBI_HOT/jss_export /brbl-dsu/jss_export
    mount -t nfs -orw,nolock,rsize=32768,wsize=32768,intr,noatime,nfsvers=3 \$GOOBI_HOT/dcs /brbl-dsu/dcs
  elif [ $CLUSTER_NAME == "yul-dc-prod" ] || [ $CLUSTER_NAME == "yul-dc-staging" ]
  then
    GOOBI_HOT="wcsfs00.its.yale.internal:/NFS_SFS_std_sngl_004/Goobi_Deposits_PROD-CC1741-BRBLDSU"
    mount -t nfs -orw,nolock,rsize=32768,wsize=32768,intr,noatime,nfsvers=3 \$GOOBI_HOT/jss_export /brbl-dsu/jss_export
    mount -t nfs -orw,nolock,rsize=32768,wsize=32768,intr,noatime,nfsvers=3 \$GOOBI_HOT/dcs /brbl-dsu/dcs
  fi

  for i in {0..10}
  do
    t=\`printf '%02d' \$i\`
    mkdir -p /data/\$t
    mount -t nfs -orw,nolock,rsize=32768,wsize=32768,intr,noatime,nfsvers=3 wcsfs00.its.yale.internal:/yul_dc_nfs_store_\$i /data/\$t
  done" | base64 -w0)

  # create launch json template
  TEMPLATE_JSON=$(jq -n \
  --arg AWS_IAM_INSTANCE_PROFILE_ARN $AWS_IAM_INSTANCE_PROFILE_ARN \
  --arg AWS_AMI_ID $AWS_AMI_ID \
  --arg INSTANCE_TYPE ${INSTANCE_TYPE:-t2.large} \
  --arg KEY_NAME ${CLUSTER_NAME}-keypair \
  --arg CLUSTER_NAME $CLUSTER_NAME \
  --arg USERDATA $USERDATA \
  --arg AWS_CUSTOM_SECURITY_GROUP_ID $AWS_CUSTOM_SECURITY_GROUP_ID \
  '{"IamInstanceProfile":{"Arn":$AWS_IAM_INSTANCE_PROFILE_ARN},
    "ImageId":$AWS_AMI_ID,
    "InstanceType":$INSTANCE_TYPE,
    "KeyName":$KEY_NAME,
    "Monitoring":{
      "Enabled":true
    },
    "UserData":$USERDATA,
    "SecurityGroupIds":[$AWS_CUSTOM_SECURITY_GROUP_ID]}' | tr -d [:space:])

  # Get launch template version
  version=$(aws ec2 describe-launch-template-versions \
          --launch-template-name $CLUSTER_NAME-lt \
          --query "LaunchTemplateVersions[0].VersionNumber" \
          --output text)

  # create aws launch template
  LT=$(aws ec2 create-launch-template-version \
    --launch-template-name $CLUSTER_NAME-lt \
    --client-token $CLUSTER_NAME-$(expr $version + 1) \
    --launch-template-data $TEMPLATE_JSON \
    --query "LaunchTemplateVersion.LaunchTemplateName" \
    --output text)

  aws autoscaling update-auto-scaling-group \
    --auto-scaling-group-name $CLUSTER_NAME-asg \
    --launch-template "LaunchTemplateName=$LT,Version=\$Latest" \
    --vpc-zone-identifier $AWS_SUBNET_PRIVATE_IDS \
    --min-size 2 \
    --desired-capacity 3 \
    --max-size 4 \
    --no-new-instances-protected-from-scale-in

  aws autoscaling start-instance-refresh \
    --auto-scaling-group-name $CLUSTER_NAME-asg \
    --preferences "MinHealthyPercentage=50"
fi
