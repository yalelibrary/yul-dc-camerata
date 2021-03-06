[![CircleCI](https://circleci.com/gh/yalelibrary/yul-dc-camerata/tree/main.svg?style=svg)](https://circleci.com/gh/yalelibrary/yul-dc-camerata/tree/main)

# yul-dc-camerata

Coordinate services for YUL-DC project

## Prerequisites

- Download [Docker Desktop](https://www.docker.com/products/docker-desktop) and log in
- Download [AWS Command Line Interface (CLI)](https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html)
- Download [ECS Command Line Interface (CLI)](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/ECS_CLI_installation.html)
- Configure your AWS command line credentials & profile (See [Troubleshooting](##Troubleshooting) for help)

## Install

Clone the yul-dc-camerata repo and install the gem.

```bash
git clone git@github.com:yalelibrary/yul-dc-camerata.git
cd yul-dc-camerata
bundle install
rake install
```

## Updates

You can get the latest version at any point by updating the code and reinstalling

```bash
cd yul-dc-camerata
git pull origin main
bundle install
rake install
```

## Configure

Camerata will read a .cameratarc file in your path. It will traverse up the path
until it finds the first instance of .cameratarc so `/home/rob/work/yale/yul-camerata`
will look in yul-camerata, then yale, then work, then rob, then home and finally
the root, taking only the first file it finds.

This will load any Ruby code it finds in the file, which can be useful for setting
variables like so:

```ruby
ENV['AWS_DEFAULT_REGION'] = 'us-east-1'
ENV['AWS_PROFILE'] = 'your_profile'
ENV['CLUSTER_NAME'] = 'yul-test'
```

## Dynatrace

We've integrated Dynatrace OneAgent for monitoring our Docker container environments.
  - Instructions on configuring OneAgent can be found [here](https://github.com/yalelibrary/yul-dc-camerata/tree/main/base)

## General Use

Once camerata is installed on your system, interactions happen through the camerata command-line tool or through its alias `cam`. The camerata tool can be used to bring the development stack up and down locally, interact with the docker containers, deploy, run the smoke tests and otherwise do development tasks common to the various applications in the yul-dc application stack.

All builtin commands can be listed with `cam help` and individual usage information is available with `cam help COMMAND`. Please note that deployment commands (found in the `./bin` directory) are passed through and are therefore not listed by the help command. See the usage for those below.

To start the application stack, run `cam up` in the directory you are working in. Example: If you are working in the Blacklight repo, run `cam up` inside the yul-dc-blacklight directory. This is the equivalent of running `docker-compose up blacklight`. This starts all of the applications as they are all dependencies of yul-blacklight. Camerata is smart. If you start `cam up` from a blacklight code check out it will mount that code for local development (changes to the outside code will affect the inside container). If you start the `cam up` from the management application you will get the management code mounted for local development and the blacklight code will run as it is in the downloaded image. You can also start the two applications both mounted for development by starting the blacklight application with `cam up blacklight --without management`, and the management application as normal (`cam up management`); each from their respective code checkouts.

- Access the blacklight app at `http://localhost:3000`

- Access the solr instance at `http://localhost:8983`

- Access the image instance at `http://localhost:8182`

- Access the management app at `http://localhost:3001/management`

## Troubleshooting
### File permissions errors in deployed environments

If you have problems deploying Solr and Postgres, e.g.
```
cp: cannot create directory '/var/solr/data/blacklight-core/conf': Permission denied`
```
make sure that you have the correct version of ecs-cli, defined below.

## Base Docker Image
The base docker image, used for our two Ruby on Rails applications (Management and Blacklight), lives in this repository under [base/Dockerfile](base/Dockerfile). In order to rebuild this image, first edit the [base/docker-compose.yml](base/docker-compose.yml) to reflect the new version number (should use semantic versioning, just like other applications). Then
```bash
cd base
docker-compose build
docker-compose push
```


### AWS Setup
If you receive a `please set your AWS_PROFILE and AWS_DEFAULT_REGION (RuntimeError)` error when you `cam up`, you will need to set your AWS credentials. Credentials can be set in the `~/.aws/credentials` file in the following format:

```bash
[yale]
aws_access_key_id=YOUR_ACCESS_KEY
aws_secret_access_key=YOUR_SECRET_ACCESS_KEY
```

AWS credentials can also be set from the command line:

```bash
aws configure --profile yale
# Enter your credentials as follows:
AWS Access Key ID [None]: YOUR_AWS_ACCESS_KEY_ID
AWS Secret Access Key [None]: YOUR_AWS_SECRET_ACCESS_KEY
Default region name [None]: us-east-1
Default output format [None]: json
```

After your credentials have been set, you will need to export the following settings via the command line:

```bash
export AWS_PROFILE=yale && export AWS_DEFAULT_REGION=us-east-1
```

Note: AWS_PROFILE name needs to match the credentials profile name (`[yale]`). After you set the credentials, you will need to re-install camerata: `rake install`

Confirm aws-cli and ecs-cli are installed

```bash
aws --version
ecs-cli --version
```
ecs-cli version must be 1.19 or above in order to successfully deploy solr and postgres.
Confirm that your aws cli credentials are set correctly

```bash
aws iam get-user --profile yale
# should return json with your account's user name
```

If you use rbenv, you must run the following command after installing camerata: `rbenv rehash`

## Why not in the Gemfile

The reason we don't add camerata to the Gemfile is that we need camerata to start the docker containers, but we do not otherwise need to bundle our application locally. The bundle can live with in the container. Requiring camerata to be in the bundle means requiring that a full dev environment both inside and outside the container, which is a requirement we are trying to avoid.

## Local Development vs. ECS Deployment

The files here are designed to follow the principles of the [12-factor application](https://12factor.net) as closely as possible. In particular, we are making an effort to maintain a high degree of [dev-prod-parity](https://12factor.net/dev-prod-parity).

To achieve this we use a common set of docker base files with overrides for any values that are required to differ for local vs. deployment environments. We create 3 files for each service in the templates directory. One for the base, then a local override and an ecs override. These files are composed together to create the compose file used for development or deployment as needed.

file                           | contents
------------------------------ | ----------------------------------------------------------------------
`blacklight-compose.yml`       | compose definitions that are shared between all environments
`blacklight-compose.local.yml` | compose definitions required exclusively in a local docker environment
`blacklight-compose.ecs.yml`   | compose definitions required for deployment to AWS ECS
`.env`                         | No longer used. All env are in Amazon SSM
`.secrets`                     | No longer used. All secrets are in Amazon SSM

For more detail on multiple compose files see <https://docs.docker.com/compose/extends/#multiple-compose-files>.

There are multiple methods to inject configuration into the compose file and container environments; for more detail on multiple environment files see <https://docs.docker.com/compose/env-file/> and <https://docs.docker.com/compose/environment-variables/>

## ECS Tools

This repo contains prototype tooling to streamline ECS cluster management. These shell scripts are available both locally and via the camerata command line interface.

### Conventions

Assuming we use a base cluster name `panicle`, we use the following naming conventions for ECS services:

name                           | function
------------------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------------
`panicle`                      | ECS cluster name
`panicle-project`              | ECS service name
`panicle-project`              | ECS task definition name - included all container definitions
`amazon-ecs-cli-setup-panicle` | CloudFormation stack name
`panicle-ecs-params.yml`       | [local] [ECS parameters](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/cmd-ecs-cli-compose-ecsparams.html) that are not native to Docker

For the tools to run, you need the AWS CLI and ECS CLI tools installed.

You'll also need to install `yq` [a lightweight and portable command-line Yaml processor](https://mikefarah.gitbook.io/yq/) and `jq`[a lightweight and flexible command-line JSON processor.](https://stedolan.github.io/jq/)

For the tools to run, you need to set the `AWS_PROFILE` and `AWS_DEFAULT_REGION` environment variables. The tools will ask you to set the appropriate environment variables if they are missing.

### List Running Containers

```
cam cluster-ps $CLUSTER_NAME main
cam cluster-ps $CLUSTER_NAME psql
cam cluster-ps $CLUSTER_NAME solr
```

This command encapsulates [ecs-cli compose service ps](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/cmd-ecs-cli-compose-service-ps.html) and implements the above naming conventions. The command has two required parameters: the name of the cluster and the name of the task.

## Editing CPU and Memory on a Cluster

```
cam get-params $CLUSTER_NAME [Memory] [CPU]
```

This command fetches the subnets and security group for an existing
cluster and builds the `ecs-params.yml` required by the ECS CLI
tool to deploy a new compose file. This file is run automatically when a
build is called, so only needs to be run manually to set the memory and CPU
parameters. The cluster-specific params file will be prefixed with the cluster
name - e.g. `panicle-ecs-params.yml`. Second and third parameters, if present,
set the memory and cpu size for the task (defaults to 8GB and 2048) -- decreased memory
example

```
cam get-params $CLUSTER_NAME 4GB 2048
```

Valid combinations of memory and cpu documented here: <https://docs.aws.amazon.com/AmazonECS/latest/developerguide/AWS_Fargate.html#fargate-tasks-size>

## Note: In the DCE environment, you should set PUBLIC_IP=ENABLED when fetching parameters (including when running other deploy scripts when you have no parameters present), or you will have a bad time.

### Retrieving arbitrary params

Retrieving a parameter from AWS is available through the following command:

```
cam env_get $PARAM_NAME
```

This command will log the param value to the console.

### Setting a param

Setting a parameter in AWS is available through the following command:

```
cam env_set $PARAM_NAME $PARAM_VALUE [Secret Boolean]
```

This command will update or create an AWS Parameter in the store. The 'Secret Boolean' is optional. Set it to true if the value you are setting is a secret that should be of a `SecureString` type. It can otherwise be left blank.

### Copying params from one namespace to another

Moving forward, parameters will be prefixed to delineate between different deployments.

The following command can be used to copy the params of one 'namespace' to another:

```
cam env_copy $TARGET_NS [SOURCE_NS]
```

This command requires a TARGET_NS and uses it as a prefix to all known params and secrets as it sets them. If provided, the SOURCE_NS argument will act as the prefix to the source set of params. If left blank, it defaults to the params as named in /lib/camerata/app_versions.rb and /lib/camerata/secrets.rb.

### Deploy the Postgres and Solr servers

```
cam deploy-psql $CLUSTER_NAME
cam deploy-solr $CLUSTER_NAME
```

These servers have significant persistent state.  They need to be stopped before re-deploying.

### Deploy the Yale stack

```
cam deploy-blacklight $CLUSTER_NAME
cam deploy-images $CLUSTER_NAME
cam deploy-intensive-worker $CLUSTER_NAME
cam deploy-worker $CLUSTER_NAME
cam deploy-mgmt $CLUSTER_NAME
```

These commands deploy the rest of the Yale stack to the named cluster. This includes the management and blacklight Rails apps, the delayed job workers, and the IIIF image servers.

### Configure a load balancer

```
cam add-alb $CLUSTER_NAME
```

This command configures an application load balancer for the cluster and sets up rules to route requests to the apps. This only needs to be run once for a given cluster

### Build a new cluster

To build a new cluster and deploy to it, you'll put all of the above commands together. The `--enable-service-discovery` option is required when starting the services for the first time on the cluster.

1. Choose a cluster name that has not been used before. AWS seems to have an imperfect system for cleaning up resources allocated for clusters, and re-using names leads to unexpected conflicts in resource allocation.

2. `export CLUSTER_NAME=YOUR_NEW_CLUSTER_NAME_HERE`

3. `cam build-cluster $CLUSTER_NAME` to build the cluster

4. (optional) `cam get-params $CLUSTER_NAME` to read the configuration data for your new cluster

5. `DOMAIN_NAME='*.your-domain-name' cam add-alb $CLUSTER_NAME` add a load balancer for your new cluster (NOTE: This has to happen _before_ you will be able to deploy)
6. `cam deploy-solr $CLUSTER_NAME --enable-service-discovery`
7. `cam deploy-psql $CLUSTER_NAME --enable-service-discovery`
8. `cam deploy-main $CLUSTER_NAME --enable-service-discovery` to deploy the application

You should now be able to use the AWS web console to get the DNS name for your load balancer and see your application at that address.

TODO: how to get the DNS name from the command line? (a need for those who don't have console access)

Example:

### Build a new cluster in an existing VPC

1. Choose a cluster name that has not been used before. AWS seems to have an imperfect system for cleaning up resources allocated for clusters, and re-using names leads to unexpected conflicts in resource allocation.
2. You'll need to make note of your VPC ID and your private and public subnet ids inside of the VPC
3. `export CLUSTER_NAME=YOUR_NEW_CLUSTER_NAME_HERE`
4. `VPC_ID=<vpc_id> SUBNET0=<private_subnet0_id> SUBNET1=<private_subnet1_id> cam build-cluster $CLUSTER_NAME` to build the cluster configuration data for your new cluster
5. `SUBNET0=<public_subnet0_id> SUBNET1=<public_subnet1_id> cam add-alb $CLUSTER_NAME` add a load balancer for your new cluster into your VPC public subnets (NOTE: This has to happen _before_ you will be able to deploy)
6. `cam deploy-solr $CLUSTER_NAME --enable-service-discovery`
7. `cam deploy-psql $CLUSTER_NAME --enable-service-discovery`
8. `cam deploy-main $CLUSTER_NAME --enable-service-discovery` to deploy the application


### Updating a single service
In order to update or deploy a single service, run the various \*-deploy command, eg:
`cam deploy-mft mycluster` will only deploy the manifest service to the mycluster environment

The available commands are: `deploy-mft, deploy-solr, deploy-blacklight, deploy-psql, deploy-images, deploy-mgmt`


### Ingest workers

Ingest workers run in an EC2 Deployment mode (as opposed to Fargate). As such, they are deployed differently.

1. deploy an EC2 instance, and associate it with your cluster:
    `cam deploy-continst clustername`.
  * optionally, an instance type can be specified by setting the INSTANCE_TYPE variable
2. Deploy worker container(s) `cam deploy-worker`
  * optionally, the number of job processes executed inside the
  worker container can be specified by setting the WORKER_COUNT
  variable. It defaults to 1

The number of worker instances can be scaled up or down as demand
increases or decreases. The number of worker containers is limited
by the capacity of container instances present in your cluster. No
container instance can host more than 3 container instances (due
to ENI constraints).


## Running the deployment test against a deployed cluster

The deployment testing suite lives in `smoke_spec/deploy_spec.rb` at the root of this repo.

To run it against a deployed cluster:

1. Set YUL_DC_SERVER to the domain name for your deployed cluster `export YUL_DC_SERVER=collections-test.library.yale.edu`
2. `cam smoke`

## Releasing a new dependency version

1. Follow the release process laid out in the application README through to completion
2. Set the version variable to the new version with `cam push_version APP_NAME VERSION_NUMBER`
3. Start the applications with the new version and run the smoke test
4. Deploy the applications (see deployment above) Example: `cam deploy-main yul-test`

## Releasing a new app version
NOTE: ENV = test, uat, demo, staging, infra or prod
NOTE: APP = blacklight, camerata or management

1. Checkout to the `main` branch and run `git pull`

2. Ensure you have a github personal access token.
    Instructions here: <https://github.com/github-changelog-generator/github-changelog-generator#github-token> You will need to make your token available via an environment variable called `CHANGELOG_GITHUB_TOKEN`, e.g.:
    ```
    export CHANGELOG_GITHUB_TOKEN=YOUR_TOKEN_HERE
    ```

3. Increment the <APP> version and deploy using `cam release <APP>`, e.g.:
    ```
    cam release blacklight
    ```

4. Follow the steps in [Deploy a branch](#deploy-a-branch). (This step is unneccesary when deploying camerata)

5. Move any tickets that were included in this release from `For Deploy to Test` to `Review on Test` or from  `For Release` to `Ready for Acceptance`

### Deploy a branch
NOTE: If you are deploying a feature branch, it should only be deployed to the test environment!

  - Log on to VPN
  - Go to the Jenkins website in your browser (there’s a link in the project wiki: https://github.com/yalelibrary/yul-dc-documentation/wiki)
  - Click "YUL-DC-[ENV]-Deploy" on the dashboard
  - Click "Build with Parameters" in the left side navigation panel
  - In the "[APP]_VERSION" input box:
    - If you are deploying the main branch, type in the version from step 3 of "Releasing a new app version". e.g.: `v1.2.3`
    - If you are deploying a feature branch, type in the branch you want to release. e.g.: `i123-readme-updates`
  - Next to the "DEPLOY" dropdown click deploy-[APP]
  - Check the UPDATE_SSM box
  - Press "Build"
  - You will see your build in the "Build History" section in the left side navigation panel with a blinking blue circle, indicating it's in progress
    - If you press the number associated with the build, you can see the details
    - The build typically takes 10-15 minutes
    - A successful build will show a solid blue circle when finished
    - An unsuccessful build will show a solid red circle when finished
