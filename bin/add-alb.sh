#!/bin/bash -e

. $(dirname "$0")/shared-checks.sh

if check_profile && check_region && check_cluster $1 && all_pass
then
  CLUSTER_NAME=${1}
  echo "Target cluster: ${CLUSTER_NAME}"
  echo "Using AWS_PROFILE=${AWS_PROFILE}"
  echo "      AWS_DEFAULT_REGION=${AWS_DEFAULT_REGION}"
  echo

  # TODO: check that the cluster name is valid and configured before running all the other commands

  # Get the basic VPC and networking config for our cluster
  if [ -z "$SUBNET0" ]
  then
    SUBNET0=`aws cloudformation list-stack-resources \
      --stack-name amazon-ecs-cli-setup-${1} \
        --query "(StackResourceSummaries[?LogicalResourceId=='PubSubnetAz1'].PhysicalResourceId)[0]" \
          | sed -e 's/^"//' -e 's/"$//' `
  fi

  if [ -z "$SUBNET1" ]
  then
    SUBNET1=`aws cloudformation list-stack-resources \
      --stack-name amazon-ecs-cli-setup-${1} \
        --query "(StackResourceSummaries[?LogicalResourceId=='PubSubnetAz2'].PhysicalResourceId)[0]" \
          | sed -e 's/^"//' -e 's/"$//' `
  fi

  if [ -z "$VPC_ID" ]
  then
    VPC_ID=`aws cloudformation list-stack-resources \
      --stack-name amazon-ecs-cli-setup-${1} \
          --query "(StackResourceSummaries[?LogicalResourceId=='Vpc'].PhysicalResourceId)[0]" \
          | sed -e 's/^"//' -e 's/"$//' `
    DEFAULT_VPC_SG=`aws ec2 describe-security-groups \
      --filters Name=vpc-id,Values=$VPC_ID \
        --query "(SecurityGroups[?GroupName=='default'])[0].GroupId" \
          | grep -Eo -m 1 'sg-\w+'`
    else
      DEFAULT_VPC_SG=`aws ec2 describe-security-groups \
        --filters Name=vpc-id,Values=$VPC_ID \
          --query "(SecurityGroups[?GroupName=='$CLUSTER_NAME-sg'])[0].GroupId" \
            | grep -Eo -m 1 'sg-\w+'`
  fi

  echo "Extracting existing configuration"
  echo "  $VPC_ID"
  echo "  $SUBNET0"
  echo "  $SUBNET1"
  echo "  $DEFAULT_VPC_SG"
  echo

  # Create a new security group to permit ingress to the load balancer
  INGRESS_SG=`aws ec2 create-security-group \
    --group-name ${1}-alb-ingress \
    --description "Ingress from ALB to ECS cluster ${1}" \
    --vpc-id $VPC_ID \
      | grep -Eo -m 1 'sg-\w+'`

  # Allow HTTP traffic to the load balancer
  aws ec2 authorize-security-group-ingress \
    --group-id $INGRESS_SG \
    --protocol tcp --port 80 \
    --cidr 0.0.0.0/0 \
    --region=$AWS_DEFAULT_REGION

  # Allow HTTPS traffic to the load balancer
  aws ec2 authorize-security-group-ingress \
    --group-id $INGRESS_SG \
    --protocol tcp --port 443 \
    --cidr 0.0.0.0/0 \
    --region=$AWS_DEFAULT_REGION

  # Allow traffic from the load balancer to the default security group for the VPC
  aws ec2 authorize-security-group-ingress \
    --group-id $DEFAULT_VPC_SG \
    --protocol all \
    --source-group $INGRESS_SG

  # Create a new load balancer and capture it's ARN for later reference
  ALB_ARN=`aws elbv2 create-load-balancer \
    --name alb-${1}  \
    --subnets $SUBNET0 $SUBNET1 \
    --security-groups $INGRESS_SG \
      | grep -Eo -m 1 'arn:aws:elasticloadbalancing[^\"]*'`

  # Create a target group to associate the BLACKLIGHT listener to clusters
  BL_TG_ARN=`aws elbv2 create-target-group \
    --name tg-${1}-blacklight \
    --target-type ip \
    --protocol HTTP \
    --port 3000 \
    --vpc-id $VPC_ID \
    --matcher '{"HttpCode": "200,401"}' \
    --health-check-interval-seconds 90 \
    --health-check-timeout-seconds 75 \
      | grep -Eo -m 1 'arn:aws:elasticloadbalancing[^\"]*'`

  # Create a target group to associate the IMAGE listener to clusters
  IMG_TG_ARN=`aws elbv2 create-target-group \
    --name tg-${1}-images \
    --target-type ip \
    --protocol HTTP \
    --port 8182 \
    --vpc-id $VPC_ID \
    --health-check-interval-seconds 90 \
    --health-check-timeout-seconds 75 \
      | grep -Eo -m 1 'arn:aws:elasticloadbalancing[^\"]*'`

  # Create a target group to associate the MANIFEST listener to clusters
  MFST_TG_ARN=`aws elbv2 create-target-group \
    --name tg-${1}-manifests \
    --target-type ip \
    --protocol HTTP \
    --port 80 \
    --vpc-id $VPC_ID \
    --health-check-path /manifests/2041002 \
      | grep -Eo -m 1 'arn:aws:elasticloadbalancing[^\"]*'`

#  # Create a target group to associate the MANAGEMENT listener to clusters
#  MGMT_TG_ARN=`aws elbv2 create-target-group \
#    --name tg-${1}-management \
#    --target-type ip \
#    --protocol HTTP \
#    --port 3001 \
#    --vpc-id $VPC_ID \
#    --health-check-interval-seconds 90 \
#    --health-check-timeout-seconds 75 \
#    --health-check-path /management \
#      | grep -Eo -m 1 'arn:aws:elasticloadbalancing[^\"]*'`

  # Create an HTTP listener on port 80that redirects all traffice to HTTPS (port 443)
  HTTP_LISTENER_ARN=`aws elbv2 create-listener \
      --load-balancer-arn $ALB_ARN \
      --protocol HTTP \
      --port 80 \
      --default-actions "Type=redirect,RedirectConfig={Protocol=HTTPS,Port=443,Host='#{host}',Query='#{query}',Path='/#{path}',StatusCode=HTTP_301}"  \
        | grep -Eo -m 1 'arn:aws:elasticloadbalancing[^\"]*'`

  # Look up the ARN for the curationexperts.com wildcard and save it for later reference
  CERT_ARN=`aws acm list-certificates \
    --query "CertificateSummaryList[?DomainName=='$DOMAIN_NAME']" \
      | grep -Eo -m 1 'arn:aws:acm[^\"]*'`

  # Create a HTTPS listener on port 443 that defaults traffic to the BLACKLIGHT target group,
  # Capture the ARN so we can add additional rules to route specific traffic to other listeners
  HTTPS_LISTENER_ARN=`aws elbv2 create-listener \
      --load-balancer-arn $ALB_ARN \
      --protocol HTTPS \
      --port 443 \
      --certificates CertificateArn=$CERT_ARN \
      --ssl-policy ELBSecurityPolicy-2016-08 \
      --default-actions "Type=forward,TargetGroupArn=${BL_TG_ARN}" \
        | grep -Eo -m 1 'arn:aws:elasticloadbalancing[^\"]*'`

  # Add a rule to the HTTPS listener to route requests to the /iiif/ path to the IMAGE target
  aws elbv2 create-rule \
      --listener-arn $HTTPS_LISTENER_ARN \
      --priority 10 \
      --conditions "Field=path-pattern,PathPatternConfig={Values=['/iiif*']}" \
      --actions Type=forward,TargetGroupArn=$IMG_TG_ARN > /dev/null

  # Add a rule to the HTTPS listener to route requests to the /manifest/ path to the MANIFEST target
  aws elbv2 create-rule \
      --listener-arn $HTTPS_LISTENER_ARN \
      --priority 20 \
      --conditions "Field=path-pattern,PathPatternConfig={Values=['/manifests*']}" \
      --actions Type=forward,TargetGroupArn=$MFST_TG_ARN > /dev/null

  # Add a rule to the HTTPS listener to route requests to the /management/ path to the MANAGEMENT target
#  aws elbv2 create-rule \
#      --listener-arn $HTTPS_LISTENER_ARN \
#      --priority 21 \
#      --conditions "Field=path-pattern,PathPatternConfig={Values=['/management*']}" \
#      --actions Type=forward,TargetGroupArn=$MGMT_TG_ARN > /dev/null

  echo "Newly created resources:"
  echo "  Load Balancer:     $ALB_ARN"
  echo "  Blacklight Target: $BL_TG_ARN"
  echo "  Image Target:      $IMG_TG_ARN"
  echo "  Manifest Target:   $MFST_TG_ARN"
  echo "  Management Target:   $MGMT_TG_ARN"
  # echo "  Certificate:       $CERT_ARN"
  echo "  HTTP Listener:     $HTTP_LISTENER_ARN"
  echo "  HTTPS Listener:    $HTTPS_LISTENER_ARN"
  echo

fi
