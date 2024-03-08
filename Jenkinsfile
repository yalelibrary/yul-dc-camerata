pipeline {
    agent { label 'docker' }
    parameters {
        string name: 'BLACKLIGHT_VERSION', description: 'Add Blacklight Version, default value will be pulled from AWS SSM'
        string name: 'IIIF_IMAGE_VERSION', description: 'Add IIIF Image Version, default value will be pulled from AWS SSM'
        string name: 'IIIF_MANIFEST_VERSION', description: 'Add IIIF Manifest Version, default value will be pulled from AWS SSM'
        string name: 'MANAGEMENT_VERSION', description: 'Add Management Version, default value will be pulled from AWS SSM'
        choice name: 'DEPLOY', choices: ['blacklight','images','intensive-workers','management','manifest']
        choice name: 'CLUSTER', choices: ['yul-dc-test','yul-dc-uat','yul-dc-demo','yul-dc-staging','yul-dc-prod']
        booleanParam name: 'UPDATE_SSM', defaultValue: true
    }
    environment {
        AWS = credentials('aws-ci-keys')
        AWS_PROFILE = "default"
        AWS_DEFAULT_REGION = "us-east-1"
        HOME = "${WORKSPACE}"
    }
    stages {
        stage('Checkout') {
            steps {
                git branch: 'main', url: 'https://github.com/yalelibrary/yul-dc-camerata'
            }
        }
        stage('Deployment') {
            agent {
                dockerfile {
                    label 'docker'
                    filename 'jenkins.dockerfile'
                    reuseNode true
                }
            }
            stages {
                stage('Setup AWS') {
                    steps {
                        sh """
                            aws configure set default.region us-east-1
                            aws configure set aws_access_key_id ${AWS_ACCESS_KEY_ID}
                            aws configure set aws_secret_access_key ${AWS_SECRET_ACCESS_KEY}
                        """
                    }
                }
                stage('Get Params') {
                    environment {
                        VPC_ID="vpc-57bee630"
                        SUBNET0="subnet-2dc03400"
                        SUBNET1="subnet-71b55b4d"
                    }
                    steps {
                        sh "cam get-params ${CLUSTER}"
                    }
                }
                stage('Deployment') {
                    steps {
                        script {
                            if ( params.DEPLOY == 'management' ) {
                                APP='mgmt'
                            }
                            else if ( params.DEPLOY == 'manifest' ) {
                                APP='mft'
                            } else {
                                APP=params.DEPLOY
                            }
                            
                            sh "cam deploy-${APP} ${CLUSTER}"
                            
                            if ( APP == 'mgmt' ) {
                                sh "cam deploy-worker ${CLUSTER}"
                                sh "WORKER_COUNT=1 cam deploy-intensive-worker ${CLUSTER}"
                            }
                        }
                        
                    }
                }
                stage('Update SSM') {
                    when {
                        environment name: 'UPDATE_SSM', value: 'true'
                    }
                    steps {
                        echo 'updating ssm...'
                        script {
                            if ( BLACKLIGHT_VERSION != '' ) {
                                sh "cam push_version blacklight ${BLACKLIGHT_VERSION}"
                            }
                            if ( IIIF_IMAGE_VERSION != '' ) {
                                sh "cam push_version iiif_image ${IIIF_IMAGE_VERSION}"
                            }
                            if ( IIIF_MANIFEST_VERSION != '' ) {
                                sh "cam push_version iiif_manifest ${IIIF_MANIFEST_VERSION}"
                            }
                            if ( MANAGEMENT_VERSION != '' ) {
                                sh "cam push_version management ${MANAGEMENT_VERSION}"
                            }
                        }
                    }
                }
            }
        }
    }
    post {
      always {
        script {
          currentBuild.description = "${CLUSTER}:${APP}"
        }
      }
    }
}