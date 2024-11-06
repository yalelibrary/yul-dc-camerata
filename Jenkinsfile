pipeline {
    agent { label 'docker' }
    environment {
        AWS = credentials('aws-ci-keys')
        AWS_PROFILE = "default"
        AWS_DEFAULT_REGION = "us-east-1"
        HOME = "${WORKSPACE}"
    }
    stages {
        stage('Setup parameters') {
            steps {
                script {
                    END_OF_JOB_NAME="${JOB_NAME.substring(JOB_NAME.lastIndexOf('/') + 1, JOB_NAME.length())}"
                    if (END_OF_JOB_NAME == 'Prod-Deploy') {
                        properties([
                            parameters([
                                string( name: 'BLACKLIGHT_VERSION', description: 'Add Blacklight Version, default value will be pulled from AWS SSM'),
                                string( name: 'IIIF_IMAGE_VERSION', description: 'Add IIIF Image Version, default value will be pulled from AWS SSM'),
                                string( name: 'IIIF_MANIFEST_VERSION', description: 'Add IIIF Manifest Version, default value will be pulled from AWS SSM'),
                                string( name: 'MANAGEMENT_VERSION', description: 'Add Management Version, default value will be pulled from AWS SSM'),
                                choice( name: 'DEPLOY', choices: ['blacklight','images','intensive-workers','management','manifest']),
                                choice( name: 'CLUSTER', choices: ['yul-dc-prod']),
                                booleanParam( name: 'UPDATE_SSM', defaultValue: true)
                            ])
                        ])
                    } else {
                        properties([
                            parameters([
                                string( name: 'BLACKLIGHT_VERSION', description: 'Add Blacklight Version, default value will be pulled from AWS SSM'),
                                string( name: 'IIIF_IMAGE_VERSION', description: 'Add IIIF Image Version, default value will be pulled from AWS SSM'),
                                string( name: 'IIIF_MANIFEST_VERSION', description: 'Add IIIF Manifest Version, default value will be pulled from AWS SSM'),
                                string( name: 'MANAGEMENT_VERSION', description: 'Add Management Version, default value will be pulled from AWS SSM'),
                                choice( name: 'DEPLOY', choices: ['blacklight','images','intensive-workers','management','manifest']),
                                choice( name: 'CLUSTER', choices: ['yul-dc-test','yul-dc-uat','yul-dc-demo']),
                                booleanParam( name: 'UPDATE_SSM', defaultValue: true)
                            ])
                        ])
                    }
                }
            }
        }
        stage('Checkout') {
            steps {
                git branch: '2917_AddSmokeTests', url: 'https://github.com/yalelibrary/yul-dc-camerata'
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
                stage('Deployment') {
                    environment {
                        VPC_ID="vpc-57bee630"
                        SUBNET0="subnet-2dc03400"
                        SUBNET1="subnet-71b55b4d"
                        CLUSTER_NAME="${CLUSTER}"
                    }
                    steps {
                        script {
                            if ( params.DEPLOY == 'management' ) {
                                APP='mgmt'
                                DEPLOY_VERSION="${MANAGEMENT_VERSION}"
                            }
                            else if ( params.DEPLOY == 'manifest' ) {
                                APP='mft'
                                DEPLOY_VERSION="${IIIF_MANIFEST_VERSION}"
                            } else {
                                APP=params.DEPLOY
                                if ( params.DEPLOY == 'blacklight' ) {
                                    DEPLOY_VERSION="${BLACKLIGHT_VERSION}"
                                }
                                else if ( params.DEPLOY == 'images' ) {
                                    DEPLOY_VERSION="${IIIF_IMAGE_VERSION}"
                                }
                                else if ( params.DEPLOY == 'intensive-workers' ) {
                                    DEPLOY_VERSION="${MANAGEMENT_VERSION}"
                                }
                            }
                            if ("${DEPLOY_VERSION}" == null || "${DEPLOY_VERSION}" == '') {
                                currentBuild.result = 'ABORTED'
                                DEPLOY_VERSION="NOT DEPLOYED!! No version"
                                error("Please enter a value for the version you want to deploy")
                            } else if ( "${DEPLOY_VERSION}".indexOf(" ") > -1 ) {
                                currentBuild.result = 'ABORTED'
                                DEPLOY_VERSION="INVALAD VERSION [${DEPLOY_VERSION}]"
                                error("The version includes a space")
                            } else {
                                sh "cam deploy-${APP} ${CLUSTER}"
                                if ( APP == 'mgmt' ) {
                                    sh "cam deploy-worker ${CLUSTER}"
                                    sh "WORKER_COUNT=1 cam deploy-intensive-worker ${CLUSTER}"
                                }
                            }
                        }
                    }
                }
                stage('Smoke Tests') {
                    steps {
                        sh "CLUSTER_NAME=${CLUSTER} cam smoke"
                    }
                    failure {
                        script {
                            echo 'revert deployment...'
                            DEPLOY_VERSION = "${currentBuild.previousSuccessfulBuild.buildVariables["DEPLOY_VERSION"]}"        
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
            currentBuild.description = "${CLUSTER}:${APP}:${DEPLOY_VERSION}"
            }
        }
    }
}