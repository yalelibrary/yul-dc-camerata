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

## General Use

Once camerata is installed on your system, interactions happen through the camerata command-line tool or through its alias `cam`. The camerata tool can be used to bring the development stack up and down locally, interact with the docker containers, deploy, run the smoke tests and otherwise do development tasks common to the various applications in the yul-dc application stack.

All builtin commands can be listed with `cam help` and individual usage information is available with `cam help COMMAND`. Please note that deployment commands (found in the `./bin` directory) are passed through and are therefore not listed by the help command. See the usage for those below.

To start the application stack, run `cam up` in the directory you are working in. Example: If you are working in the Blacklight repo, run `cam up` inside the yul-dc-blacklight directory. This is the equivalent of running `docker compose up blacklight`. This starts all of the applications as they are all dependencies of yul-blacklight. Camerata is smart. If you start `cam up` from a blacklight code check out it will mount that code for local development (changes to the outside code will affect the inside container). If you start the `cam up` from the management application you will get the management code mounted for local development and the blacklight code will run as it is in the downloaded image. You can also start the two applications both mounted for development by starting the blacklight application with `cam up blacklight --without management`, and the management application as normal (`cam up management`); each from their respective code checkouts.

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
The base docker image, used for our two Ruby on Rails applications (Management and Blacklight), lives in this repository under [base/Dockerfile](base/Dockerfile). In order to rebuild this image, first edit the [base/docker-compose.yml](base/docker-compose.yml) to reflect the new version number (should use semantic versioning, just like other applications). 

```bash
cd base
docker compose build
docker compose push
```

Then you'll need to prep cam for use locally.

```
cd .. \\ get back to main directory
bundle install
rake install
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

## Running Smoke Tests
Smoke tests are run before every deployment in every environment.  To run the tests locally both the Management and Blacklight apps must be running locally as well, although this is not recommended.  The smoke tests are specifically for deployed environments.

To set up running smoke tests in your terminal:

```
docker build . -f jenkins.dockerfile
```
Once built use the sha to run the container.  At the end of the build look for `writing image sha256:d01508e3c1a7c7738807fb076e9b595d87552b2ce8451a919869b84e1da166632`. The sha will be different each time.
```
docker run -it d01508e3c1a7c7738807fb076e9b595d87552b2ce8451a919869b84e1da166632 bash
```
Then you will be in a bash shell inside the container and you can run all the smoke tests or individual ones from there.  To set which cluster to test and to set up environment variables needed for camerata to run the tests you may need to export a few variables.

```
export CLUSTER_NAME=yul-dc-test AWS_PROFILE=yale AWS_DEFAULT_REGION=us-east-1
```


To run all smoke tests:

```bash
cam smoke
```

To run tests individually:
```bash
rspec smoke_spec/deploy_spec.rb:56
```

## Why not in the Gemfile

The reason we don't add camerata to the Gemfile is that we need camerata to start the docker containers, but we do not otherwise need to bundle our application locally. The bundle can live with in the container. Requiring camerata to be in the bundle means requiring that a full dev environment both inside and outside the container, which is a requirement we are trying to avoid.

## Local Development vs. ECS Deployment
- See the [wiki](https://github.com/yalelibrary/yul-dc-documentation/wiki/Camerata-Documentation#local-development-vs-ecs-deployment) for further information on local vs ECS deployment

## ECS Tools

This repo contains prototype tooling to streamline ECS cluster management. These shell scripts are available both locally and via the camerata command line interface.

### Conventions
- See the [wiki](https://github.com/yalelibrary/yul-dc-documentation/wiki/Camerata-Documentation#naming-conventions) for further information on naming conventions

### List Running Containers
- See the [wiki](https://github.com/yalelibrary/yul-dc-documentation/wiki/Camerata-Documentation#list-running-containers) for further information on running containers

## Editing CPU and Memory on a Cluster
- See the [wiki](https://github.com/yalelibrary/yul-dc-documentation/wiki/Camerata-Documentation#editing-cpu-and-memory-on-a-cluster) for further information on clusters

## Ingest workers
- See the [wiki](https://github.com/yalelibrary/yul-dc-documentation/wiki/Camerata-Documentation#ingest-workers) for further information on ingest workers.

## Running the deployment test against a deployed cluster
- See the [wiki](https://github.com/yalelibrary/yul-dc-documentation/wiki/Camerata-Documentation#running-the-deployment-test-against-a-deployed-cluster) for further information on deploying test against a deployed cluster.

## Releasing a new dependency version
- See the [wiki](https://github.com/yalelibrary/yul-dc-documentation/wiki/Camerata-Documentation#releasing-a-new-version) for further information on releasing a new dependency version.

## Releasing a new app version
- See the [wiki](https://github.com/yalelibrary/yul-dc-documentation/wiki/Camerata-Documentation#releasing-a-new-version) for further information on releasing a new version.