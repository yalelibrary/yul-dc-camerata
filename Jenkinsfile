pipeline {
    agent {
        dockerfile {
            label 'docker'
            filename 'Dockerfile.camerata'
            args '--user root'
        }
    }
    environment {
        AWS = credentials('aws-kb849_api-access')
        AWS_PROFILE = 'default'
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
        stage('Cam deployment') {
            steps {
                sh 'bundle exec cam ps yul-dc-test'
            }
        }
    }
}
