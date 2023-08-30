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
      AWS_REGION = 'us-east-1'
    }
    stages {
        stage('Build and Install camerata') {
            steps {
                sh """
                    gem install bundler
                    bundle install
                    rake install
                """
            }
        }
        stage('Get Params'){
          steps {
            sh """
                export VPC_ID=vpc-57bee630
                export SUBNET0=subnet-2dc03400 
                export SUBNET1=subnet-71b55b4d

                cam get-params yul-dc-test
              """
          }
        }
    }
}
