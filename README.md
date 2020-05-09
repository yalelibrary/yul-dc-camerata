# yul-dc-camerata
Coordinate services for YUL-DC project

### Prerequisites
- Download [Docker Desktop](https://www.docker.com/products/docker-desktop) and log in

### If this is your first time working in this repo or the Dockerfile has been updated you will need to (re)build your services

- Push to the git repository
- Set the environment variable for the tag to the git commit
  ```bash
  export CAMERATA_TAG=$(git rev-parse --short HEAD)
  ```
& build your image based on the docker-compose file
  ``` bash
  docker-compose build
  ```
- If appropriate, push the tagged image to the Dockerhub repository
  ```bash
  docker-compose push
  ```

### Environment Variables for Development

Create the following file to override anything in .env. The following two values must be overridden.
```
SOLR_URL=http://solr:8983/solr/blacklight-development
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
- **NOTE: In Progress** Access the image instance at `http://localhost:8182`
- **NOTE: In Progress** Access the manifests instance at `http://localhost`
