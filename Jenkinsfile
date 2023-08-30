pipeline {
    agent {
        dockerfile {
            label 'docker'
            filename 'Dockerfile'
        }
    }
    stages {
        stage('Build and Install camerata') {
            steps {
                sh """
                    ls -l
                    gem install bundler
                    bundle install
                    rake install
                    which cam
                    which aws
                """
            }
        }
    }
}
