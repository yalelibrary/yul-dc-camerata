pipeline {
    agent { label 'docker' }
    environment {
        AWS=credentials('aws-ci-keys')
        AWS_PROFILE="default"
        AWS_DEFAULT_REGION="us-east-1"
        HOME="${WORKSPACE}"
        VPC_ID="vpc-57bee630"
        SUBNET0="subnet-2dc03400"
        SUBNET1="subnet-71b55b4d"
        CLUSTER_NAME="${CLUSTER}"
    }
    stages {
        stage('Setup parameters') {
            steps {
                script {
                    END_OF_JOB_NAME="${JOB_NAME.substring(JOB_NAME.lastIndexOf('/') + 1, JOB_NAME.length())}"
                    if (END_OF_JOB_NAME == 'Prod-Deploy') {
                        properties([
                            parameters([
                                string( name: 'BLACKLIGHT_VERSION_INPUT', description: 'Add Blacklight Version, default value will be pulled from AWS SSM'),
                                string( name: 'IIIF_IMAGE_VERSION_INPUT', description: 'Add IIIF Image Version, default value will be pulled from AWS SSM'),
                                string( name: 'IIIF_MANIFEST_VERSION_INPUT', description: 'Add IIIF Manifest Version, default value will be pulled from AWS SSM'),
                                string( name: 'MANAGEMENT_VERSION_INPUT', description: 'Add Management Version, default value will be pulled from AWS SSM'),
                                choice( name: 'DEPLOY', choices: ['blacklight','images','intensive-workers','management','manifest']),
                                choice( name: 'CLUSTER', choices: ['yul-dc-prod']),
                                booleanParam( name: 'UPDATE_SSM', defaultValue: true)
                            ])
                        ])
                    } else {
                        properties([
                            parameters([
                                string( name: 'BLACKLIGHT_VERSION_INPUT', description: 'Add Blacklight Version, default value will be pulled from AWS SSM'),
                                string( name: 'IIIF_IMAGE_VERSION_INPUT', description: 'Add IIIF Image Version, default value will be pulled from AWS SSM'),
                                string( name: 'IIIF_MANIFEST_VERSION_INPUT', description: 'Add IIIF Manifest Version, default value will be pulled from AWS SSM'),
                                string( name: 'MANAGEMENT_VERSION_INPUT', description: 'Add Management Version, default value will be pulled from AWS SSM'),
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
                stage('Deploy') {
                    steps {
                        script {
                            if ( params.DEPLOY == 'management' ) {
                                APP='mgmt'
                                DEPLOY_VERSION="${MANAGEMENT_VERSION_INPUT}"
                            }
                            else if ( params.DEPLOY == 'manifest' ) {
                                APP='mft'
                                DEPLOY_VERSION="${IIIF_MANIFEST_VERSION_INPUT}"
                            } else {
                                APP=params.DEPLOY
                                if ( params.DEPLOY == 'blacklight' ) {
                                    DEPLOY_VERSION="${BLACKLIGHT_VERSION_INPUT}"
                                }
                                else if ( params.DEPLOY == 'images' ) {
                                    DEPLOY_VERSION="${IIIF_IMAGE_VERSION_INPUT}"
                                }
                                else if ( params.DEPLOY == 'intensive-workers' ) {
                                    DEPLOY_VERSION="${MANAGEMENT_VERSION_INPUT}"
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
                    post {
                        success {
                            script {
                                echo 'updating ssm...'
                                if ( BLACKLIGHT_VERSION_INPUT != '' ) {
                                    sh "CLUSTER_NAME=${CLUSTER} cam push_version blacklight ${BLACKLIGHT_VERSION_INPUT}"
                                }
                                if ( IIIF_IMAGE_VERSION_INPUT != '' ) {
                                    sh "CLUSTER_NAME=${CLUSTER} cam push_version iiif_image ${IIIF_IMAGE_VERSION_INPUT}"
                                }
                                if ( IIIF_MANIFEST_VERSION_INPUT != '' ) {
                                    sh "CLUSTER_NAME=${CLUSTER} cam push_version iiif_manifest ${IIIF_MANIFEST_VERSION_INPUT}"
                                }
                                if ( MANAGEMENT_VERSION_INPUT != '' ) {
                                    sh "CLUSTER_NAME=${CLUSTER} cam push_version management ${MANAGEMENT_VERSION_INPUT}"
                                }
                            }
                        }
                        failure {
                            script {
                                switch (params.DEPLOY) {
                                    case 'blacklight': 
                                        lastSuccessVersion=sh(returnStdout: true, script: "cam env_get /${CLUSTER}/BLACKLIGHT_VERSION")
                                        break
                                    case 'management':
                                        lastSuccessVersion=sh(returnStdout: true, script: "cam env_get /${CLUSTER}/MANAGEMENT_VERSION")
                                        break
                                    case 'manifest':
                                        lastSuccessVersion=sh(returnStdout: true, script: "cam env_get /${CLUSTER}/IIIF_MANIFEST_VERSION")
                                        break
                                    case 'images':
                                        lastSuccessVersion=sh(returnStdout: true, script: "cam env_get /${CLUSTER}/IIIF_IMAGE_VERSION")
                                        break
                                    case 'intensive-workers':
                                        lastSuccessVersion=sh(returnStdout: true, script: "cam env_get /${CLUSTER}/MANAGEMENT_VERSION")
                                        break
                                }
                                sh """
                                    echo "deploy version before redefine \${DEPLOY_VERSION}"
                                    export DEPLOY_VERSION="${lastSuccessVersion}"      
                                    export APP="${APP}"      
                                    echo "deploy version after redefine \${DEPLOY_VERSION}"
                                    echo "revert deployment...of \${APP} on \${CLUSTER} to version \${DEPLOY_VERSION}"
                                    cam deploy-${APP} ${CLUSTER}
                                """
                                if ( APP == 'mgmt' ) {
                                    sh "cam deploy-worker ${CLUSTER}"
                                    sh "WORKER_COUNT=1 cam deploy-intensive-worker ${CLUSTER}"
                                }
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
