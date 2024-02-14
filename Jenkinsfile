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
    parameters {
      choice choices: ['yul-dc-test'], name: 'CLUSTER'
      string 'BLACKLIGHT_VERSION'
      string 'MANAGEMENT_VERSION'
      string 'IIIF_MANIFEST_VERSION'
      string 'IIIF_IMAGE_VERSION'
      choice choices: ['deploy-blacklight',
                      'deploy-mgmt',
                      'deploy-mft',
                      'deploy-images',
                      'deploy-worker',
                      'deploy-intensive-worker'], 
             name: 'DEPLOY'
      booleanParam defaultValue: true, name: 'UPDATE_SSM'
    }
    environment {
      AWS = credentials('aws-ci-keys')
    }
    stages {
        stage('Get Params'){
          steps {
            sh """
                export HOME=${WORKSPACE}
                export AWS_PROFILE=default
                export AWS_DEFAULT_REGION=us-east-1

                export VPC_ID=vpc-57bee630
                export SUBNET0=subnet-2dc03400 
                export SUBNET1=subnet-71b55b4d

                aws configure set aws_access_key_id $AWS_ACCESS_KEY_ID
                aws configure set aws_secret_access_key $AWS_SECRET_ACCESS_KEY
                aws configure set default.region us-east-1

                cam get-params ${CLUSTER}
              """
          }
        }
        stage('Update Cluster'){
          steps {
            sh """
              if [ $DEPLOY = 'deploy-intensive-worker' ]; then
                export WORKER_COUNT=1
              else
                export WORKER_COUNT=12
              fi

              if [ "$UPDATE_SSM" = "true" ]
              then

                echo "UPDATING AWS SSM"
                if [ ! -z "$BLACKLIGHT_VERSION" ]
                then
                  cam push_version blacklight $BLACKLIGHT_VERSION
                fi
                
                if [ ! -z "$MANAGEMENT_VERSION" ]
                then
                cam push_version management $MANAGEMENT_VERSION
                fi
                
                if [ ! -z "$IIIF_MANIFEST_VERSION" ]
                then
                  cam push_version iiif_manifest $IIIF_MANIFEST_VERSION
                fi
                
                if [ ! -z "$IIIF_IMAGE_VERSION" ]
                then
                  cam push_version iiif_image $IIIF_IMAGE_VERSION
                fi
                  
                  cam push_version camerata $CAMERATA_VERSION    
              fi

              cam $DEPLOY $CLUSTER

              if [ $DEPLOY = "deploy-mgmt" ]; then
                cam deploy-worker $CLUSTER
                WORKER_COUNT=1 cam deploy-intensive-worker $CLUSTER
              fi
            """
          }
        }
    }
}
