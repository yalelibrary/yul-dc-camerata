# Yul-DC Base

This Dockerfile represents a common base for all Rails based apps in our stack to work from.  This will allow for 
simpler updates and more controlled changes to dependencies and for faster deployment and dev pulls for all.

It builds on the Phusion Passenger based Dockerfiles found here https://github.com/phusion/passenger-docker and 
adds some common OS level dependencies that we need for our projects such as Node and Yarn.

## Dynatrace

We've integrated Dynatrace OneAgent for monitoring our Docker container environments. In order to correctly connect OneAgent with the Base image, you will need to sign into Dynatrace with the Dynatrace environment ID (nhd42358) and Activegate Address (https://nhd42358.live.dynatrace.com). 

```bash
cd base
cam sh management 
docker login -u nhd42358 https://nhd42358.live.dynatrace.com
```

It will ask you for a password. This is the PaaS token associated with Yale's Dynatrace account.
It can be accessed via 

```bash
cam env_get DYNATRACE_TOKEN
```

Once you've logged in successfully you will need to rebuild your image. 

```bash
docker-compose build
```