[![CircleCI](https://circleci.com/gh/yalelibrary/yul-dc-camerata/tree/master.svg?style=svg)](https://circleci.com/gh/yalelibrary/yul-dc-camerata/tree/master)

# yul-dc-camerata

Coordinate services for YUL-DC project

## Prerequisites

- Download [Docker Desktop](https://www.docker.com/products/docker-desktop) and log in

## Starting the services

- Start all the services locally for development

  ```bash
  export RAILS_ENV=development
  bin/localup up
  ```

- Access the blacklight app at `http://localhost:3000`

- Access the solr instance at `http://localhost:8983`

- Access the image instance at `http://localhost:8182`

- Access the manifests instance at `http://localhost`

- Access the management app at `http://localhost:3001/management`

## Local Development vs. ECS Deployment

The files here are designed to follow the principles of the [12-factor application](https://12factor.net) as closely as possible. In particular, we are making an effort to maintain a high degree of [dev-prod-parity](https://12factor.net/dev-prod-parity).

To achieve this we use a common set of docker base files with overrides for any values that are required to differ for local vs. deployment environments. The file naming convention assumed here is:

file                          | contents
----------------------------- | ----------------------------------------------------------------------------------------------------
`docker-compose.yml`          | compose definitions that are shared between all environments
`local.override.yml`          | compose definitions required exclusively in a local docker environment
`docker-compose.ecs.yml`      | compose definitions required for deployment to AWS ECS
`.env`                        | environment variables injected into the compose file, but not automatically visible in containers
`.secrets`                    | secure information not to be added to source control

For more detail on multiple compose files see <https://docs.docker.com/compose/extends/#multiple-compose-files>.

There are multiple methods to inject configuration into the compose file and container environments; for more detail on multiple environment files see <https://docs.docker.com/compose/env-file/> and <https://docs.docker.com/compose/environment-variables/>

## ECS Tools

This repo contains prototype tooling to streamline ECS cluster management.

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
bin/cluster-ps.sh $CLUSTER_NAME
```

TODO: This one isn't working quite right...
This command encapsulates [ecs-cli compose service ps](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/cmd-ecs-cli-compose-service-ps.html) and implements the above naming conventions. The command has one required parameter which is the name of the target cluster.

### Get ECS Parameter for a Cluster

```
bin/get-params.sh $CLUSTER_NAME [Memory] [CPU]
```

This command fetches the subnets and security group for an existing cluster and builds the `ecs-params.yml` required by the ECS CLI tool to deploy a new compose file. The cluster-specific params file will be prefixed with the cluster name - e.g. `panicle-ecs-params.yml`. Second and third parameters, if present, set the memory and cpu size for the task (defaults to 8GB and 2048) -- decreased memory example

```
bin/get-params.sh $CLUSTER_NAME 4GB 2048
```

Valid combinations of memory and cpu documented here: <https://docs.aws.amazon.com/AmazonECS/latest/developerguide/AWS_Fargate.html#fargate-tasks-size>

### Deploy the Postgres and Solr servers

```
bin/deploy-psql.sh $CLUSTER_NAME
bin/deploy-solr.sh $CLUSTER_NAME
```
These servers have significant persistent state; an existing cluster will not
usually need these re-deployed.  More info about how to safely take down, restart,
or update these servers to come.

### Deploy the Yale stack

```
bin/deploy-main.sh $CLUSTER_NAME
```

This command deploys the rest of the Yale stack to the named cluster.  This includes the management and blacklight Rails apps and the IIIF image and manifest servers. You must have a valid params file obtained by running `bin/get-params` against your cluster first. You must also create a `.secrets` file with valid S3, basic auth, and Honeybadger credentials; see `secrets-template` for the correct format.  For deployments to complete succesfully you also need to set a 16-byte (32 character) RAILS_MASTER_KEY provided by your team lead.

### Configure a load balancer

```
bin/add-alb.sh $CLUSTER_NAME
```

This command configures an application load balancer for the cluster and sets up rules to route requests to the blacklight, image, management, and manifest apps.
This only needs to be run once for a given cluster

### Build a new cluster

To build a new cluster and deploy to it, you'll put all of the above commands together.  The `--enable-service-discovery` option is required when starting the services for the first time on the cluster.

1. Choose a cluster name that has not been used before. AWS seems to have an imperfect system for cleaning up resources allocated for clusters, and re-using names leads to unexpected conflicts in resource allocation.
1. `export CLUSTER_NAME=YOUR_NEW_CLUSTER_NAME_HERE`
1. `bin/build-cluster.sh $CLUSTER_NAME` to build the cluster
1. (optional) `bin/get-params.sh $CLUSTER_NAME` to read the configuration data for your new cluster
1. `bin/add-alb.sh $CLUSTER_NAME --enable-service-discovery` add a load balancer for your new cluster (NOTE: This has to happen _before_ you will be able to deploy)
1. `bin/deploy-solr.sh $CLUSTER_NAME --enable-service-discovery`
1. `bin/deploy-psql.sh $CLUSTER_NAME --enable-service-discovery`
1. `bin/deploy-main.sh $CLUSTER_NAME --enable-service-discovery` to deploy the application

You should now be able to use the AWS web console to get the DNS name for your load balancer and see your application at that address.
TODO: how to get the DNS name from the command line? (a need for those who don't have console access)

Example:

## Running the deployment test against a deployed cluster

The deployment testing suite lives in `/spec/deploy_spec.rb` at the root of this repo.

To run it against a deployed cluster:

1. `bundle install`
2. Set YUL_DC_SERVER to the domain name for your deployed cluster `export YUL_DC_SERVER=collections-test.curationexperts.com`
3. Ensure http basic auth credentials for Blacklight are set in your `.secrets` file (See [secrets-template](./secrets-template) for an example). Otherwise the test suite will set its user and password to what is in env vars before defaulting to 'test'. To set via env vars:
   - Set HTTP_USERNAME to the known Blacklight http basic auth username for your deployed cluster `export HTTP_USERNAME=<basic-auth-username>`
   - Set HTTP_PASSWORD to the known Blacklight http basic auth password for you deployed cluster `export HTTP_PASSWORD=<basic-auth-password>`
4. `rspec spec/deploy_spec.rb`

## Releasing a new version

1. Decide on a new version number. We use [semantic versioning](https://github.com/yalelibrary/yul-dc-camerata/wiki/Semantic-Versioning).
2. Update the version number in `.github_changelog_generator`
3. Update the version number in `.env`
4. `github_changelog_generator --user yalelibrary --project yul-dc-camerata --token $YOUR_GITHUB_TOKEN`
5. Commit and merge the changes you just made with a message like "Prep for x.y.z release"
6. Once those changes are merged to the `master` branch, in the github web UI go to `Releases` and tag a new release with the right version number. Paste in the release notes for this version from the changelog you generated. In the release notes, split out `Features`, `Bug Fixes`, and `Other`
7. Once the CI build has completed for `master`, deploy the updated components to staging using the appropriate deploy scripts.  Example: `bin/deploy-main.sh yul-test`
