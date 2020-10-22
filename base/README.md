# Yul-DC Base

This Dockerfile represents a common base for all Rails based apps in our stack to work from.  This will allow for 
simpler updates and more controlled changes to dependencies and for faster deployment and dev pulls for all.

It builds on the Phusion Passenger based Dockerfiles found here https://github.com/phusion/passenger-docker and 
adds some common OS level dependencies that we need for our projects such as Node and Yarn.

## Dynatrace	

We've integrated Dynatrace OneAgent for monitoring our Docker container environments. The Dynatrace dashboard can be reached here https://nhd42358.live.dynatrace.com. Ideally we will only monitor deployed environments, so logging into Dynatrace from the command line in locally running or development environments is NOT recommended.
