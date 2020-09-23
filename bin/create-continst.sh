#!/bin/bash -ex
. $(dirname "$0")/shared-checks.sh
. $(dirname "$0")/efs-fun.sh

if check_profile && check_region && check_cluster $1 && all_pass ; then
CLUSTER_NAME=$1
  ## Create a policy for ecsInstanceRole IAM Role
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

  function check_role {
    echo "Checking for ecsInstanceRole"
    AWS_IAM_INSTANCE_PROFILE_ARN=$(aws iam list-instance-profiles-for-role \
    --role-name ecsInstanceRole \
    --query 'InstanceProfiles[0].Arn' \
    --output text) || create_role
  }

  function create_key {
    echo "Creating new keypair for ${CLUSTER_NAME}-keypair.pem"
    aws ec2 create-key-pair --key-name $CLUSTER_NAME-keypair  --query 'KeyMaterial' \
      --output text > $CLUSTER_NAME-keypair.pem && chmod 400 $CLUSTER_NAME-keypair.pem
  }


  check_role

  if [ -z "${AWS_IAM_INSTANCE_PROFILE_ARN}" ];then
    echo "Could not obtain instance profile."
    exit 1
  fi


  AWS_AMI_ID=$(aws ssm get-parameters --names '/aws/service/ecs/optimized-ami/amazon-linux-2/recommended/image_id' \
    --query 'Parameters[0].Value' --output text)

  if [ -z "${AWS_AMI_ID}" ] ; then
    echo "Could not retrieve latest AMI"
    exit 1
  fi


  aws ec2 describe-key-pairs --key-names $CLUSTER_NAME-keypair ||  create_key

  AWS_SUBNET_PUBLIC_ID=$(yq r manifestly-ecs-params.yml 'run_params.network_configuration.awsvpc_configuration.subnets[0]') 
  AWS_CUSTOM_SECURITY_GROUP_ID=$(yq r manifestly-ecs-params.yml 'run_params.network_configuration.awsvpc_configuration.security_groups[0]') 

  USERDATA=$(echo "#!/bin/bash
  echo ECS_CLUSTER=$CLUSTER_NAME >> /etc/ecs/ecs.config " | base64)

  ## Create one EC2 instance in the public subnet
  AWS_EC2_INSTANCE_ID=$(aws ec2 run-instances \
  --image-id $AWS_AMI_ID \
  --instance-type t2.micro \
  --tag-specifications "ResourceType=instance,Tags=[{Key=Name, Value=$CLUSTER_NAME-container-instance}]" \
  --key-name $CLUSTER_NAME-keypair \
  --associate-public-ip-address \
  --monitoring "Enabled=false" \
  --security-group-ids $AWS_CUSTOM_SECURITY_GROUP_ID \
  --subnet-id $AWS_SUBNET_PUBLIC_ID \
  --iam-instance-profile Arn=$AWS_IAM_INSTANCE_PROFILE_ARN \
  --user-data $USERDATA \
  --query 'Instances[0].InstanceId' \
  --output text)

  ## Check if the instance one is running
  ## It will take some time for the instance to get ready
  aws ec2 describe-instance-status \
  --instance-ids $AWS_EC2_INSTANCE_ID --output text
fi
