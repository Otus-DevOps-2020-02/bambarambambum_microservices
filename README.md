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
<details><summary>Homework 18 (gitlab-ci-1)</summary>

### Task 1 - Build
1) In order for containers to run in containers (DinD), we need to re-register gitlab-runner
```
docker exec -it gitlab-runner gitlab-runner register --run-untagged --locked=false --docker-volumes /var/run/docker.sock:/var/run/docker.sock
```
2) Change build_job :, add a docker image
```
image: docker:latest
```
3) We can use the Dockerfile from previous lessons (docker-monolith)
```
script:
    - echo 'Building'
    - cd docker-monolith
    - docker build -t gitlab-docker-app:1.0 .
```
4) Now we need to refine test_unit_job:, adding an image and transferring commands from before_script:
```
test_unit_job:
  image: ruby:2.4.2
  stage: test
  services:
    - mongo:latest
  script:
    - cd reddit
    - bundle install
    - ruby simpletest.rb
```

### Task 2 - Gitlab-Runner
1) The easiest way
1.1) Because we can run infinitely many (in theory) gitlab-runner on one machine, we can launch a new container
```
docker run -d --name gitlab-runner2 --restart always \
-v /srv/gitlab-runner/config:/etc/gitlab-runner \
-v /var/run/docker.sock:/var/run/docker.sock \
gitlab/gitlab-runner:latest
```
1.2) And take advantage of non-interactive gitlab-runner registration
```
docker exec gitlab-runner2 gitlab-runner register \
           --locked=false \
           --non-interactive \
           --url http://34.107.83.160/ \
           --registration-token v3aNxnjLdRzwYUpmf19e \
           --description "Docker Runner" \
           --tag-list "linux,bionic,ubuntu,docker" \
           --executor docker \
           --docker-image "alpine:latest" \
           --docker-volumes /var/run/docker.sock:/var/run/docker.sock
```
1.3) We can repeat these steps endlessly by simply changing the name of the container

2) The hard way
2.1) We can take advantage of the ready-made role from ansible galaxy
https://galaxy.ansible.com/riemers/gitlab-runner
2.2) Instances can be deployed using terraform
2.3) We can also bake an image using packer with docker and gitlab-runner
3) Slack chat integration - #mikhail_androsov in devops-team-otus.slack.com
</details>
<details><summary>Homework 18 (gitlab-ci-1)</summary>

### Task 1 - MongoDB-Exporter
1) We can take this exporter https://github.com/percona/mongodb_exporter
2) Need to download repository
```
git clone https://github.com/percona/mongodb_exporter.git
```
3) Go to the folder with the repository and do docker build
```
docker build -t ${USERNAME}/mongodb-exporter:1.0 .
```
4) Now add the mongodb-exporter service to docker-compose.yml
```
  mongodb-exporter:
    image: ${USERNAME}/mongodb-exporter:1.0
    container_name: mongodb-exporter
    command:
      - '--mongodb.uri=mongodb://post_db:27017'
    networks:
      - back_net
```
5) Run docker-compose
```
docker-compose up -d
```

### Task 2 - Blackbox-Exporter
1) We can use official image from dockerhub https://hub.docker.com/r/prom/blackbox-exporter
2) Since we need a configuration file for blackbox_exporter to work, create it
```
modules:
  tcp_connect:
    prober: tcp
    timeout: 5s

  http_2xx:
    prober: http
    timeout: 5s
    http:
```
3) Create a new image prom/blackbox-exporter look and add the config there.
```
FROM prom/blackbox-exporter:v0.16.0
ADD blackbox.yml /config/
```
4) Do docker build
```
docker build -t ${USERNAME}/blackbox-exporter:1.0 .
```
5) Now add the blackbox-exporter service to docker-compose.yml
blackbox-exporter:
    image: ${USERNAME}/blackbox-exporter:1.0
    container_name: blackbox-exporter
    ports:
      - '9115:9115'
    command:
      - '--config.file=/config/blackbox.yml'
    networks:
      - back_net
6) Now we need to update the prometheus.yml configuration file. We will check the availability of http and tcp
```
- job_name: 'blackbox-tcp_connect'
        metrics_path: /probe
        params:
            module: [tcp_connect]
        static_configs:
          - targets:
            - '34.78.221.243:9292'
        relabel_configs:
            -
                source_labels:
                  - __address__
                target_label: __param_target
            -
                source_labels:
                  - __param_target
                target_label: instance
            -
                replacement: "blackbox-exporter:9115"
                target_label: __address__

      - job_name: 'blackbox-http'
        metrics_path: /probe
        params:
            module: [http_2xx]
        static_configs:
          - targets:
            - '34.78.221.243:9292'
        relabel_configs:
            -
                source_labels:
                  - __address__
                target_label: __param_target
            -
                source_labels:
                  - __param_target
                target_label: instance
            -
                replacement: "blackbox-exporter:9115"
                target_label: __address__
```
7) Update the prometheus image to add the updated configuration file
```
docker build -t ${USERNAME}/prometheus .
```
8) Run docker-compose
```
docker-compose up -d
```

### Task 3 - Makefile
* See Makefile
1) make - build & push all images
2) make build_all - only build all images
3) make push_all - only push all images
</details>
