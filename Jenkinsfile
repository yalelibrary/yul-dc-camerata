pipeline {
    agent {
        dockerfile {
            label 'docker'
            filename 'Dockerfile.camerata'
            args '--user root'
        }
    }
    parameters {
        string(name: 'CLUSTER_NAME', defaultValue: 'yul-dc-test', description: 'ECS Cluster Name' )
    }
    environment {
        AWS = credentials('aws-kb849_api-access')
        AWS_PROFILE = 'default'
        AWS_DEFAULT_REGION = 'us-east-1'
    }
    stages {
        stage('Set AWS configuration') {
            steps {
                sh '''
                    aws configure set aws_access_key_id $AWS_ACCESS_KEY_ID
                    aws configure set aws_secret_access_key $AWS_ACCESS_KEY_ID
                    aws configure set default.region us-east-1
                '''
            }
        }
        stage('Get AWS Configs') {
            steps {
                script {
                    vpcid = sh(
                        script: 'aws ec2 describe-vpcs \
                                --filter Name=tag:Name,Values="Library VPC" \
                                --query Vpcs[].VpcId --output text',
                        returnStdout: true
                    ).trim()
                    privateSubnet1 = sh(
                        script: "aws ec2 describe-subnets \
                                --filter Name=vpc-id,Values=${vpcid} \
                                --filter Name=tag:SubnetType,Values=Public \
                                --query Subnets[0].SubnetId --output text",
                        returnStdout: true
                    ).trim()
                    privateSubnet2 = sh(
                        script: "aws ec2 describe-subnets \
                                --filter Name=vpc-id,Values=${vpcid} \
                                --filter Name=tag:SubnetType,Values=Public \
                                --query Subnets[1].SubnetId --output text",
                        returnStdout: true
                    ).trim()
                }
            }
        }
        stage('Get cluster params') {
            steps {
                sh """
                    VPC_ID=${vpcid} SUBNET0=${privateSubnet1} SUBNET1=${privateSubnet2} bundle exec cam get-params $CLUSTER_NAME
                """
            }
        }
    }
}
