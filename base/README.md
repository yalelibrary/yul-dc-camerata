# Yul-DC Base

This Dockerfile represents a common base for all Rails based apps in our stack to work from.  This will allow for 
simpler updates and more controlled changes to dependencies and for faster deployment and dev pulls for all.

It builds on the Phusion Passenger based Dockerfiles found here https://github.com/phusion/passenger-docker and 
adds some common OS level dependencies that we need for our projects such as Node and Yarn.

## Base Image Development

There are are 3 major steps to developing the base image:
1) Developing Image
2) Pushing Image
3) Updating downstream images

**Develop Image**

In the Camerata repo:

- Make a branch
- `cd` into `base` directory
- Update the version number in `base/docker-compose.yml` (using semantic versioning)
    - *eg*: `image: yalelibraryit/dc-base:v<new.version.number>`
    - This will ensure that each build will be tagged with the **new** version number
- Open `base/Dockerfile` in your editor
- Make your changes
- Run `docker-compose build` to build the image
- Confirm that the image builds
- Run `docker-compose up` to start up the service
- Run `docker exec base sh` to connect to the running container and examine its contents

**Push Image**

Once you have a Dockerfile that is the correct recipe for your image:
- Run `docker-compose push`
- Commit your changes and make a **PR**
- Run `rake install`
    - This will set you up to test the build with the downstream services

**Updating Downstream Images**

For each **downstream image** that will require the update from base:
- `cd` into the repo for the service
- Make a branch
- Edit the `FROM` line with the new **version number**
    - `FROM yalelibraryit/dc-base:v<new.version.number>`
- To test the new build
    - Run `cam build <name-of-service>`
    - Run `cam up <service-name>`
    - Check to see that the service comes up and behaves as expected
- Commit your changes and make a **PR**

## Dynatrace	

We've integrated Dynatrace OneAgent for monitoring our Docker container environments. The Dynatrace dashboard can be reached here https://nhd42358.live.dynatrace.com. During local development, you may encounter the following error while building (`dc build`) an image locally.

```bash
ERROR: Service 'base' failed to build : invalid from flag value nhd42358.live.dynatrace.com/linux/oneagent-codemodules:all: Get https://nhd42358.live.dynatrace.com/v2/linux/oneagent-codemodules/manifests/all: no basic auth credentials
```

This means that you need to authenticate against the Dynatrace Docker registry. This command is usually needed once for each computer until the authentication expires.

1.) Open a terminal within the repo:	

```bash	
cam env_get /yul-dc-ingest/DYNATRACE_TOKEN	
```	
This will return the PaaS token associated with the Dynatrace account. You will need it in step 3. 	

2.) Next, sign in using the Dynatrace environment ID (nhd42358) and Activegate Address (https://nhd42358.live.dynatrace.com)	

```bash	
docker login -u nhd42358 https://nhd42358.live.dynatrace.com	
```	

3.) It will ask you for a password. Paste in the PaaS token you accessed in step 1. 	

4.) Once you've logged in successfully you will need to rebuild your image.	

```bash	
docker-compose build	
```
