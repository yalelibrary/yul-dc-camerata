pipeline {
    agent {
        dockerfile {
            label 'docker'
            filename 'Dockerfile.camerata'
        }
    }
    stages {
        stage('Check Cam version') {
            steps {
                sh 'bundle exec cam version'
            }
        }
    }
}
