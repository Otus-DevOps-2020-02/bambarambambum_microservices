# bambarambambum_microservices
**<details><summary>Homework 15 (Docker-2)</summary>**
### Task 1
* What is the difference between a container and an image?
The main difference between the image and the container is the writable top layer.
To create a container, the Docker engine takes an image, adds a writable top layer and initializes various parameters (network ports, container name, identifier and resource limits).
### Task 2 - Infra
* Ready infrastructure for reddit-docker-app has the following form
1. Infra
    1. ansible
        1. environments
            1. inventory.gcp.yml
        2. playbooks
            1. base.yml
            2. deploy.yml
            3. docker.yml
            4. site.yml
        3. ansible.cfg
        4. requirements.txt
    2. packer
        1. docker.json
        2. variables.json.example
    3. terraform
        1. main.tf
        2. outputs.tf
        3. terraform.tfvars.example
        4. variables.tf
1) We bake python, pip, docker.io, pip-docker module into the image (packer + ansible provisioning)
2) With Terraform, we deploy the required number of instances from the finished image
3) We launch a playbook that checks whether everything is installed, downloads the docker image and launches it
</details>
<details><summary>Homework 16 (Docker-3)</summary>

### Task 1
To start containers with new variables without restarting the builder, use the following commands
```
docker run -d --network=reddit --network-alias=app_post_db --network-alias=app_comment_db mongo:latest
docker run -d --network=reddit --network-alias=app_post --env POST_DATABASE_HOST=app_post_db androsovm/post:1.0
docker run -d --network=reddit --network-alias=app_comment --env COMMENT_DATABASE_HOST=app_comment_db androsovm/comment:1.0
docker run -d --network=reddit -p 9292:9292 --env POST_SERVICE_HOST=app_post --env COMMENT_SERVICE_HOST=app_comment androsovm/ui:1.0
```

### Task 2
1) /ui/Dockerfile
```
FROM alpine:3.9
RUN apk --no-cache update && apk --no-cache --update add \
    ruby-full ruby-dev build-base ruby-bundler \
    && bundle install \
    && bundle clean --force
```
```
androsovm/ui        2.0                 4f32edbbdc96        3 hours ago          430MB
androsovm/ui        4.0                 b733a4f805f9        About a minute ago   236MB
```
2) /comment/Dockerfile
```
FROM alpine:3.9
RUN apk --no-cache update && apk --no-cache --update add \
    ruby-full ruby-dev build-base ruby-bundler \
    && bundle install \
    && bundle clean --force
```
```
androsovm/comment   1.0                 f2b8bb71005e        4 hours ago          784MB
androsovm/comment   3.0                 1de43db40158        About a minute ago   233MB
```
3) /post-py/Dockerfile
```
RUN apk --no-cache --update add build-base && \
    pip install --no-cache-dir -r /app/requirements.txt && \
    apk del build-base
```
```
androsovm/post      1.0                 67d1538d796c        8 hours ago          110MB
androsovm/post      2.0                 82b1e3091aa8        2 hours ago          106MB
```
For faster work of the builder, we also need to replace the ADD instructions with COPY and transfer all the steps for installing packages and copying files to the end of the Dockerfile.
</details>
<details><summary>Homework 17 (Docker-4)</summary>

### Task 1 - docker-compose.yml
1) See the docker-compose.yml and .env.example

### Task 2 - Project name
```
docker-compose [-f <arg>...] [options] [COMMAND] [ARGS...]
-p, --project-name NAME     Specify an alternate project name
                            (default: directory name)
```
Example:
```
docker-compose -p hm17 up -d
```
```
Creating network "hm17_front_net" with the default driver
Creating network "hm17_back_net" with the default driver
Creating volume "hm17_post_db" with default driver
...
```
We can also name containers using docker-compose.yml
```
some_service:
  container_name: name_name_name
```

### Task 3 - Override
1) We need to copy the source to the docker host
```
docker-machine scp -r ui/ docker-host:/home/docker-user/ui
docker-machine scp -r comment/ docker-host:/home/docker-user/comment
docker-machine scp -r post-py/ docker-host:/home/docker-user/post-py
```
2) Created a docker-compose.override.yml file
```
...
  ui:
    volumes:
      - /home/docker-user/ui:/app
    command: 'puma --debug -w 2'

  post:
    volumes:
      - /home/docker-user/post-py:/app

  comment:
    volumes:
      - /home/docker-user/comment:/app
    command: 'puma --debug -w 2'

volumes:
  ui:
  post:
  comment:
```
3) Start and check
```
docker-compose -f docker-compose.yml -f docker-compose.override.yml up -d
docker ps
```
</details>
