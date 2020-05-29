# yul-dc-camerata
Coordinate services for YUL-DC project

### Prerequisites
- Download [Docker Desktop](https://www.docker.com/products/docker-desktop) and log in

### Environment Variables for Development

Create the following file to override anything in .env. The following two values must be overridden.
```
SOLR_CORE=blacklight-development
SOLR_URL=http://solr:8983/solr/
POSTGRES_HOST=db
```
### Starting the services
- Start the service & any dependencies it has in the docker-compose file
  ``` bash
  docker-compose up [service_name]

  docker-compose up blacklight
  docker-compose up solr
  docker-compose up db
  ```
- Access the blacklight app at `http://localhost:3000`
- Access the solr instance at `http://localhost:8983`
- Access the image instance at `http://localhost:8182`
- Access the manifests instance at `http://localhost`

## Local Development vs. ECS Deployment
The files here are designed to follow the principles of the [12-factor application](https://12factor.net) as closely
as possible.  In particular, we are making an effort to maintain a high degree of [dev-prod-parity](https://12factor.net/dev-prod-parity).

To achieve this we use a common set of docker base files with overrides for any values that are required to differ for
local vs. deployment environments.  The file naming convention assumed here is:

| file                           | contents |
|--------------------------------|----------|
| `docker-compose.yml`           | compose definitions that are shared between all environments |
| `docker-compose.override.yml`  | compose definitions required exclusively in a local docker environment |
| `docker-compose.ecs.yml`       | compose definitions required for deployment to AWS ECS |
| `.env`                         | environment variables injectected into the compose file, but not automatically visible in containers |
| `.env.development`             | environment varialbes unique to local development environments |
| `.env.ecs`                     | environment variables required in deployment environments |

For more detail on multiple compose files see https://docs.docker.com/compose/extends/#multiple-compose-files.

There are multiple methods to inject configuration into the compose file and container environments; for more detail on
multiple environment files see https://docs.docker.com/compose/env-file/ and https://docs.docker.com/compose/environment-variables/

## ECS Tools
This repo contains prototype tooling to streamline ECS cluster management.

### Conventions
Assuming we use a base cluster name `panicle`, we use the following naming conventions for ECS services:  

| name               | function             |
|--------------------|----------------------|
| `panicle`          | ECS cluster name     |
| `panicle-project`  | ECS service name |
| `panicle-project`  | ECS task definition name - included all container definitions |
| `amazon-ecs-cli-setup-panicle`  | CloudFormation stack name  |
| `panicle-ecs-params.yml` | [local] [ECS parameters](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/cmd-ecs-cli-compose-ecsparams.html) that are not native to Docker |

For the tools to run, you need the AWS CLI and ECS CLI tools installed.

You'll also need to install `yq` [a lightweight and portable command-line Yaml processor](https://mikefarah.gitbook.io/yq/)

For the tools to run, you need to set the `AWS_PROFILE` and `AWS_DEFAULT_REGION` environment variables.
The tools will ask you to set the appropriate environment variables if they are missing.

### List Running Containers
```
bin/cluster-ps.sh $CLUSTER_NAME
```
This command encapsulates [ecs-cli compose service ps](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/cmd-ecs-cli-compose-service-ps.html)
and implements the above naming conventions.
The command has one required parameter which is the name of the target cluster.

### Get ECS Parameter for a Cluster
```
bin/get-params.sh $CLUSTER_NAME
```
This command fetches the subnets and security group for an existing cluster and builds the
`ecs-params.yml` required by the ECS CLI tool to deploy a new compose file. The cluster-specific
params file will be prefixed with the cluster name - e.g. `panicle-ecs-params.yml`.

### Deploy a reference container
```
bin/deploy-simple.sh $CLUSTER_NAME
```
This command deploys a single container PHP application to the named cluster.  You must have a valid params
file obatined by running `bin/get-params` against your cluster first.  

### Deploy the Yale stack
```
bin/deploy-full.sh $CLUSTER_NAME
```
This command deploys the full Yale stack to the named cluster.  You must have a valid params
file obtained by running `bin/get-params` against your cluster first.  You must also create a `.secrets`
file with valid S3 credentials; see `secrets-template` for the correct format.

### Build a new cluster
```
bin/build-cluster.sh $CLUSTER_NAME
```
This command builds a new, empty cluster with the supplied cluster name.  Once you build the cluster,
you can use `get-params.sh` to read the configuration data and one of the deploy variants to deploy to it.

EXAMPLE
```
bin/build-cluster.sh panicle
bin/deploy-simple.sh panicle
```

### Configure a load balancer
```
bin/add-alb.sh $CLUSTER_NAME
```
This command configures an application load balancer for the cluster and sets up rules to rout requests
to the blacklight, image, and manifest apps.
