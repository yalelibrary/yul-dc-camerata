# Yul-DC Base

This Dockerfile represents a common base for all Rails based apps in our stack to work from.  This will allow for 
simpler updates and more controlled changes to dependencies and for faster deployment and dev pulls for all.

It builds on the Phusion Passenger based Dockerfiles found here https://github.com/phusion/passenger-docker and 
adds some common OS level dependencies that we need for our projects such as Node and Yarn.

## Dynatrace

We've integrated Dynatrace OneAgent for monitoring our Docker container environments. In order to correctly connect OneAgent with the Base image, follow these instructions.

1.) Open a terminal within the Camerata repo:

```bash
cd base
cam env_get /yul-dc-ingest/DYNATRACE_TOKEN
```
This will return the PaaS token associated with the Dynatrace account. You will need it in step 3. 

2.) Next, sign in using the Dynatrace environment ID (nhd42358) and Activegate Address (https://nhd42358.live.dynatrace.com)

```bash
docker login -u nhd42358 https://nhd42358.live.dynatrace.com
```

3.) It will ask you for a password. Paste in the PaaS token we accessed in step 1. 

4.) Once you've logged in successfully you will need to rebuild your image. Make sure you are in the base directory. 

```bash
cd base
docker-compose build
```