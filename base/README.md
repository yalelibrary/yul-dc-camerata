# Yul-DC Base

This Dockerfile represents a common base for all Rails based apps in our stack to work from.  This will allow for 
simpler updates and more controlled changes to dependencies and for faster deployment and dev pulls for all.

It builds on the Phusion Passenger based Dockerfiles found here https://github.com/phusion/passenger-docker and 
adds some common OS level dependencies that we need for our projects such as Node and Yarn.

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
