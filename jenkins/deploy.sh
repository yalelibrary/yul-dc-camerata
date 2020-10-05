/usr/bin/env bash

export PATH=$PATH:/usr/local/bin
export AWS_PROFILE=default
export AWS_DEFAULT_REGION=us-east-1

declare -A CLUSTER_URL
CLUSTER_URL=( ["yul-dc-test"]="collections-test.library.yale.edu"
              ["yul-dc-uat"]="collections-uat.library.yale.edu"
              ["yul-dc-demo"]="collections-demo.library.yale.edu" )

gem install bundler

bundle install --quiet

#install camerata gem
rake install

CAMERATA_VERSION=`cam version | awk {'print "v"$3}'`

#Retrieve service definitions from AWS ECS Cluster
VPC_ID=vpc-57bee630 SUBNET0=subnet-2dc03400 SUBNET1=subnet-71b55b4d cam get-params $CLUSTER_NAME


#Push application versions to AWS SSM
if [ "$UPDATE_SSM" = "true" ]
then
	echo "UPDATING AWS SSM"
    if [ ! "$BLACKLIGHT_VERSION" = '' ]
    then
    	cam push_version blacklight $BLACKLIGHT_VERSION
    fi

    if [ ! "$MANAGEMENT_VERSION" = '' ]
    then
		cam push_version management $MANAGEMENT_VERSION
    fi

    if [ ! "$IIIF_MANIFEST_VERSION" = '' ]
    then
    	cam push_version iiif_manifest $IIIF_MANIFEST_VERSION
    fi

    if [ ! "$IIIF_IMAGE_VERSION" = '' ]
    then
    	cam push_version iiif_image $IIIF_IMAGE_VERSION
    fi

    cam push_version camerata $CAMERATA_VERSION
fi

echo "UPDATE_SSM -> ${UPDATE_SSM}"
echo "BLACKLIGHT -> ${BLACKLIGHT_VERSION}"
echo "MANAGEMENT -> ${MANAGEMENT_VERSION}"
echo "IIIF_MANIFEST -> ${IIIF_MANIFEST_VERSION}"
echo "IIIF_IMAGE -> ${IIIF_IMAGE_VERSION}"
echo "CAMERATA -> ${CAMERATA_VERSION}"

#Update containers from Git
cam deploy-main $CLUSTER_NAME
cam deploy-worker $CLUSTER_NAME

sleep 10

# Run smoke tests after deployment
YUL_DC_SERVER=${CLUSTER_URL["$CLUSTER_NAME"]} cam smoke

