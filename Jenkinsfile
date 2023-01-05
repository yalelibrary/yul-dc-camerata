pipeline {
    agent {
        dockerfile {
            label 'docker'
            filename 'Dockerfile.camerata'
        }
    }
    environment {
        AWS = credentials('aws-kb849_api-access')
        AWS_DEFAULT_REGION = 'us-east-1'
    }
    stages {
        stage('Check Cam version') {
            steps {
                sh 'bundle exec cam version'
            }
        }
        stage('Cam deployment') {
            steps {
                sh 'aws s3 ls'
            }
        }
    }
}
