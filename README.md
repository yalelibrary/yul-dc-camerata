[![CircleCI](https://circleci.com/gh/yalelibrary/yul-dc-camerata/tree/master.svg?style=svg)](https://circleci.com/gh/yalelibrary/yul-dc-camerata/tree/master)

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
git pull origin master
bundle install
rake install
```

## General Use

Once camerata is installed on your system, interactions happen through the camerata command-line tool or through its alias `cam`. The camerata tool can be used to bring the development stack up and down locally, interact with the docker containers, deploy, run the smoke tests and otherwise do development tasks common to the various applications in the yul-dc application stack.

All builtin commands can be listed with `cam help` and individual usage information is available with `cam help COMMAND`. Please note that deployment commands (found in the `./bin` directory) are passed through and are therefore not listed by the help command. See the usage for those below.

To start the application stack, run `cam up` in the directory you are working in. Example: If you are working in the Blacklight repo, run `cam up` inside the yul-dc-blacklight directory. This is the equivalent of running `docker-compose up blacklight`. This starts all of the applications as they are all dependencies of yul-blacklight. Camerata is smart. If you start `cam up` from a blacklight code check out it will mount that code for local development (changes to the outside code will affect the inside container). If you start the `cam up` from the management application you will get the management code mounted for local development and the blacklight code will run as it is in the downloaded image. You can also start the two applications both mounted for development by starting the blacklight application with `--without management` and the management application `--without solr --without db` each from their respective code checkouts.

- Access the blacklight app at `http://localhost:3000`

- Access the solr instance at `http://localhost:8983`

- Access the image instance at `http://localhost:8182`

- Access the manifests instance at `http://localhost`

- Access the management app at `http://localhost:3001/management`

## Troubleshooting

If you receive a `please set your AWS_PROFILE and AWS_DEFAULT_REGION (RuntimeError)` error when you `cam up`, you will need to set your AWS credentials. Credentials can be set in the `~/.aws/credentials` file in the following format:

```bash
[dce-hosting]
aws_access_key_id=YOUR_ACCESS_KEY
aws_secret_access_key=YOUR_SECRET_ACCESS_KEY
```

AWS credentials can also be set from the command line:

```bash
aws configure --profile dce-hosting
# Enter your credentials as follows:
AWS Access Key ID [None]: YOUR_AWS_ACCESS_KEY_ID
AWS Secret Access Key [None]: YOUR_AWS_SECRET_ACCESS_KEY
Default region name [None]: us-east-1
Default output format [None]: json
```

After your credentials have been set, you will need to export the following settings via the command line:

```bash
export AWS_PROFILE=dce-hosting && export AWS_DEFAULT_REGION=us-east-1
```

Note: AWS_PROFILE name needs to match the credentials profile name (`[dce-hosting]`). After you set the credentials, you will need to re-install camerata: `rake install`

Confirm aws-cli and ecs-cli are installed

```bash
aws --version
ecs-cli --version
```

Confirm that your aws cli credentials are set correctly

```bash
aws iam get-user --profile dce-hosting
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
`.env`                         | No longer used. All env should be in Amazon SSM
`.secrets`                     | No longer used. All secrets should be in Amazon SSM

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

These servers have significant persistent state; an existing cluster will not usually need these re-deployed. More info about how to safely take down, restart, or update these servers to come.

### Deploy the Yale stack

```
cam deploy-main $CLUSTER_NAME
```

This command deploys the rest of the Yale stack to the named cluster. This includes the management and blacklight Rails apps and the IIIF image and manifest servers. You must have a valid params file obtained by running `cam get-params` against your cluster first. You must also create a `.secrets` file with valid S3, basic auth, and Honeybadger credentials; see `secrets-template` for the correct format. For deployments to complete succesfully you also need to set a 16-byte (32 character) RAILS_MASTER_KEY provided by your team lead.

### Configure a load balancer

```
cam add-alb $CLUSTER_NAME
```

This command configures an application load balancer for the cluster and sets up rules to route requests to the blacklight, image, management, and manifest apps. This only needs to be run once for a given cluster

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

## Running the deployment test against a deployed cluster

The deployment testing suite lives in `/spec/deploy_spec.rb` at the root of this repo.

To run it against a deployed cluster:

1. Set YUL_DC_SERVER to the domain name for your deployed cluster `export YUL_DC_SERVER=collections-test.curationexperts.com`

2. Set the HTTP loging vars:

  - Set HTTP_USERNAME to the known Blacklight http basic auth username for your deployed cluster `export HTTP_USERNAME=<basic-auth-username>`
  - Set HTTP_PASSWORD to the known Blacklight http basic auth password for you deployed cluster `export HTTP_PASSWORD=<basic-auth-password>`

3. `cam smoke`

## Releasing a new dependency version

1. Follow the release process laid out in the application README through to completion
2. Set the version variable to the new version with `cam push_version APP_NAME VERSION_NUMBER`
3. Start the applications with the new version and run the smoke test
4. Deploy the applications (see deployment above) Example: `cam deploy-main yul-test`

## Releasing a version of Camerata

1. Run the release command: `cam release camerata`
2. Move any tickets that were included in this release from `For Release` to `Ready for Acceptance`
