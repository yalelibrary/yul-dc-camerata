#!/bin/bash -e

. $(dirname "$0")/shared-checks.sh

if check_profile && check_region && check_cluster $1 && all_pass
then
  CLUSTER_NAME=${1}
  echo "Target cluster: ${CLUSTER_NAME}"
  echo "Using AWS_PROFILE=${AWS_PROFILE}"
  echo "      AWS_DEFAULT_REGION=${AWS_DEFAULT_REGION}"
  echo

  DEFAULT_VPC_SG=`aws ec2 describe-security-groups \
    --filters Name=vpc-id,Values=$VPC_ID \
      --query "(SecurityGroups[?GroupName=='$CLUSTER_NAME-sg'])[0].GroupId" \
        | grep -Eo -m 1 'sg-\w+'`

  echo "Extracting existing configuration"
  echo "  $VPC_ID"
  echo "  $SUBNET0"
  echo "  $SUBNET1"
  echo "  $DEFAULT_VPC_SG"
  echo

  # Create a new security group to permit ingress to the load balancer
  INGRESS_SG=`aws ec2 create-security-group \
    --group-name ${1}-alb-mgmt-ingress \
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

#  # Allow HTTP traffic to the load balancer
#  aws ec2 authorize-security-group-ingress \
#    --group-id $INGRESS_SG \
#    --protocol tcp --port 80 \
#    --cidr 130.132.0.0/16 \
#    --region=$AWS_DEFAULT_REGION
#
#  # Allow HTTPS traffic to the load balancer
#  aws ec2 authorize-security-group-ingress \
#    --group-id $INGRESS_SG \
#    --protocol tcp --port 443 \
#    --cidr 130.132.0.0/16 \
#    --region=$AWS_DEFAULT_REGION
#
#  # Allow HTTP traffic to the load balancer
#  aws ec2 authorize-security-group-ingress \
#    --group-id $INGRESS_SG \
#    --protocol tcp --port 80 \
#    --cidr 128.36.0.0/16 \
#    --region=$AWS_DEFAULT_REGION
#
#  # Allow HTTPS traffic to the load balancer
#  aws ec2 authorize-security-group-ingress \
#    --group-id $INGRESS_SG \
#    --protocol tcp --port 443 \
#    --cidr 128.36.0.0/16 \
#    --region=$AWS_DEFAULT_REGION
#
#  # Allow HTTP traffic to the load balancer
#  aws ec2 authorize-security-group-ingress \
#    --group-id $INGRESS_SG \
#    --protocol tcp --port 80 \
#    --cidr 172.16.0.0/12 \
#    --region=$AWS_DEFAULT_REGION
#
#  # Allow HTTPS traffic to the load balancer
#  aws ec2 authorize-security-group-ingress \
#    --group-id $INGRESS_SG \
#    --protocol tcp --port 443 \
#    --cidr 172.16.0.0/12 \
#    --region=$AWS_DEFAULT_REGION

  # Allow traffic from the load balancer to the default security group for the VPC
  aws ec2 authorize-security-group-ingress \
    --group-id $DEFAULT_VPC_SG \
    --protocol all \
    --source-group $INGRESS_SG

  # Create a new load balancer and capture it's ARN for later reference
  ALB_ARN=`aws elbv2 create-load-balancer \
    --name alb-${1}-mgmt  \
    --scheme internal \
    --subnets $SUBNET0 $SUBNET1 \
    --security-groups $INGRESS_SG \
      | grep -Eo -m 1 'arn:aws:elasticloadbalancing[^\"]*'`

  # Create a target group to associate the MANAGEMENT listener to clusters
  MGMT_TG_ARN=`aws elbv2 create-target-group \
    --name tg-${1}-management \
    --target-type ip \
    --protocol HTTP \
    --port 3001 \
    --vpc-id $VPC_ID \
    --health-check-interval-seconds 90 \
    --health-check-timeout-seconds 75 \
    --health-check-path /management \
      | grep -Eo -m 1 'arn:aws:elasticloadbalancing[^\"]*'`

  # Create an HTTP listener on port 80 that redirects all traffice to HTTPS (port 443)
  HTTP_LISTENER_ARN=`aws elbv2 create-listener \
      --load-balancer-arn $ALB_ARN \
      --protocol HTTP \
      --port 80 \
      --default-actions "Type=redirect,RedirectConfig={Protocol=HTTPS,Port=443,Host='#{host}',Query='#{query}',Path='/#{path}',StatusCode=HTTP_301}"  \
        | grep -Eo -m 1 'arn:aws:elasticloadbalancing[^\"]*'`

  # Look up the ARN for the library.yale.edu wildcard and save it for later reference
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
      --default-actions "Type=forward,TargetGroupArn=${MGMT_TG_ARN}" \
        | grep -Eo -m 1 'arn:aws:elasticloadbalancing[^\"]*'`

  # Add a rule to the HTTPS listener to route requests to the /management/ path to the MANAGEMENT target
#  aws elbv2 create-rule \
#      --listener-arn $HTTPS_LISTENER_ARN \
#      --priority 21 \
#      --conditions "Field=path-pattern,PathPatternConfig={Values=['/management*']}" \
#      --actions Type=forward,TargetGroupArn=$MGMT_TG_ARN > /dev/null

  echo "Newly created resources:"
  echo "  Load Balancer:     $ALB_ARN"
  echo "  Management Target:   $MGMT_TG_ARN"
  echo "  Certificate:       $CERT_ARN"
  echo "  HTTP Listener:     $HTTP_LISTENER_ARN"
  echo "  HTTPS Listener:    $HTTPS_LISTENER_ARN"
  echo

fi