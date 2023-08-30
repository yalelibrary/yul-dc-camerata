pipeline {
    agent {
        dockerfile {
            label 'docker'
            filename 'Dockerfile'
        }
    }
    options {
      buildDiscarder(logRotator(numToKeepStr: '10'))
    }
    environment {
      AWS = credentials('aws-ci-keys')
    }
    stages {
        stage('Get Params'){
          steps {
            sh """
                export HOME=${WORKSPACE}
                export AWS_DEFAULT_REGION=us-east-1
                export VPC_ID=vpc-57bee630
                export SUBNET0=subnet-2dc03400 
                export SUBNET1=subnet-71b55b4d

                aws configure set aws_access_key_id $AWS_ACCESS_KEY_ID
                aws configure set aws_secret_access_key $AWS_SECRET_ACCESS_KEY
                aws configure set default.region us-east-1

                cam get-params yul-dc-test
              """
          }
        }
    }
}
