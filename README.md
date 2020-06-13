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
<details><summary>Homework 19 (monitoring-1)</summary>

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
<details><summary>Homework 20 (monitoring-2)</summary>

### Task 1 - * (Collect Docker metrics with Prometheus)
1) We will use the setup instructions - https://docs.docker.com/config/daemon/prometheus/
* docker-machine host - /etc/docker/daemon.json
```
{
  "metrics-addr" : "0.0.0.0:9323",
  "experimental" : true
}
```
* prometheus.yml
```
...
- job_name: 'docker'
        static_configs:
          - targets:
            - '34.78.221.243:9323'
```
2) Do not forget to reload the docker daemon
```
sudo systemctl daemon-reload
sudo systemctl restart docker
```
3) For Grafana, download a ready-made dashboard - https://grafana.com/grafana/dashboards/1229

### Task 1 - * (Collect Docker metrics with Telegraf)
1) Create a new file: /monitoring/telegraf/telegraf.conf
```
[[outputs.prometheus_client]]
    listen = ":9126"

[[inputs.docker]]
    endpoint = "unix:///var/run/docker.sock"
    container_names = []
    timeout = "5s"
    perdevice = false
    total = false
```
2) Create a new Dockerfile: /monitoring/telegraf/Dockerfile
```
FROM telegraf:1.14.3-alpine
ADD telegraf.conf /etc/telegraf/
```
3) Create a new build
```
docker build -t $USER_NAME/telegraf .
```
4) Edit a docker-compose-monitoring.yml
```
telegraf:
    image: ${USER_NAME}/telegraf
    container_name: telegraf
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
    networks:
      - back_net
```
5) Grafana dashboard is stored in the directory /monitoring/grafana/dashboards/Telegraf_Docker_Monitorings.json

### Task 1 - * (Alertmanager email notification)
1) monitoring/alertmanager/config.yml
```
route:
  receiver: 'slack-email-notifications'

receivers:
- name: 'slack-email-notifications'
  slack_configs:
  - channel: '#mikhail_androsov'
  email_configs:
    - to: $GMAIL_ACCOUNT
      from: $GMAIL_ACCOUNT
      smarthost: smtp.gmail.com:587
      auth_username: $GMAIL_ACCOUNT
      auth_identity: $GMAIL_ACCOUNT
      auth_password: $GMAIL_PASSWORD
```

### Task 2 - ** (Dashboards & datasource provisioning)
1) Create a provisioning folder (monitoring/grafana/provisioning)
2) Create a dashboards subfolder (monitoring/grafana/provisioning/dashboards) and a datasources subfolder (monitoring/grafana/provisioning/datasources)
3) Create a dash.yml file (monitoring/grafana/provisioning/dashboards/dash.yml)
```
- name: 'default'
  org_id: 1
  folder: ''
  type: 'file'
  options:
    folder: '/var/lib/grafana/dashboards'
```
4) Create a data.yml file (monitoring/grafana/provisioning/datasources/data.yml)
```
datasources:
    -  access: 'proxy'
       editable: true
       is_default: true
       name: 'Prometheus server'
       org_id: 1
       type: 'prometheus'
       url: 'http://prometheus:9090'
       version: 1
```
5) Create a Dockerfile (monitoring/grafana/Dockerfile) file and add our data to the docker image
```
FROM grafana/grafana:5.0.0
ADD ./provisioning /etc/grafana/provisioning
ADD ./dashboards /var/lib/grafana/dashboards
```
6) Build image
```
docker build -t $USER_NAME/grafana .
```
7) Update file docker-compose-monitroing.yml
```
...
  grafana:
    image: ${USER_NAME}/grafana
...
```
8) Restart all containers and remove the volume of Graphana (used Makefile)
```
make stop
docker volume rm docker_grafana_data
or
docker-compose down
docker-compose -f docker-compose-monitoring.yaml down
docker volume rm docker_grafana_data
```
9) Start all containers (Used Makefile)
```
make run
or
docker-compose up -d
docker-compose -f docker-compose-monitoring.yaml up -d
```

### Task 2 - ** (Stackdriver)
1) Create a folder stackdriver (monitoring/stackdriver)
2) We will use the completed image prometheuscommunity/stackdriver-exporter:v0.9.0. For his work we need GCP account credentials.
3) Create a Dockerfile file (monitorin/stackdriver/Dockerfile)
```
FROM prometheuscommunity/stackdriver-exporter:v0.9.0
ADD ./project.json /key/project.json
```
4) Build image
```
docker build -t $USER_NAME/stackdriver .
```
5) Update the Prometheus configuration and build image
```
...
      - job_name: 'stackdriver'
        static_configs:
          - targets:
            - 'stackdriver:9255'
...
docker build -t $USER_NAME/prometheus .
```
6) Update configuration docker-compose-monitoring.yml
```
...
  stackdriver:
    image: ${USER_NAME}/stackdriver
    container_name: stackdriver
    environment:
      - GOOGLE_APPLICATION_CREDENTIALS=/key/project.json
      - STACKDRIVER_EXPORTER_GOOGLE_PROJECT_ID=PROJECT_NAME
      - STACKDRIVER_EXPORTER_MONITORING_METRICS_TYPE_PREFIXES=compute.googleapis.com/instance,pubsub.googleapis.com/subscription,redis.googleapis.com/stats
    ports:
      - '9255:9255'
    networks:
      - back_net
...
```
7) Do not push a stackdriver image to the docker hub!
8) Now we can collect many metrics
* stackdriver_gce_instance_compute_googleapis_com_instance_cpu and submetrics
* stackdriver_gce_instance_compute_googleapis_com_instance_disk and submetrics
* stackdriver_gce_instance_compute_googleapis_com_instance_network and submetrics
* stackdriver_gce_instance_compute_googleapis_com_instance_uptime
* stackdriver_monitoring_scrapes_total
* and another

### Task 3 - *** (Trickster)
* We can use part of the demo version https://github.com/tricksterproxy/trickster/blob/master/deploy/trickster-demo
1) Create a folder trickster (monitoring/trickster)
2) Create a configuration trickster.conf file (monitoring/trickster/trickster.conf)
```
[frontend]
listen_port = 8480

[negative_caches]
  [negative_caches.default]
  400 = 3
  404 = 3
  500 = 3
  502 = 3

[caches]
  [caches.fs1]
  cache_type = 'filesystem'
    [caches.fs1.filesystem]
    cache_path = '/data/trickster'
    [caches.fs1.index]
    max_size_objects = 512
    max_size_backoff_objects = 128
  [caches.mem1]
  cache_type = 'memory'
    [caches.mem1.index]
    max_size_objects = 512
    max_size_backoff_objects = 128

[tracing]
  [tracing.std1]
  tracer_type = 'stdout'
    [tracing.std1.stdout]
    pretty_print = true

[origins]
  [origins.prom1]
  origin_type = 'prometheus'
  origin_url = 'http://prometheus:9090'
  tracing_name = 'std1'
  cache_name = 'mem1'

[logging]
log_level = 'info'

[metrics]
listen_port = 8481
```
3) Create a Dockerfile file (monitorin/trickster/Dockerfile)
```
FROM tricksterproxy/trickster:1.1.0-beta
COPY trickster.conf /etc/trickster/
```
4) Build image
```
docker build -t $USER_NAME/trickster .
```
5) Update the Prometheus configuration and build image
```
...
      - job_name: 'trickster'
        static_configs:
          - targets:
            - 'trickster:8481'
...
docker build -t $USER_NAME/prometheus .
```
6) Update the Grafana provisioning datasource configuration file and build image
```
...
    - name: prom-trickster-memory-stdout
      type: prometheus
      access: proxy
      orgId: 1
      uid: ds_prom1_trickster
      url: http://trickster:8480/prom1
      version: 1
      editable: true

docker build -t $USER_NAME/grafana .
```
7) Update configuration docker-compose-monitoring.yml
```
  trickster:
    image: ${USER_NAME}/trickster
    container_name: trickster
    depends_on:
      - prometheus
      - grafana
    ports:
      - 8480:8480
      - 8481:8481
    networks:
      - back_net
```
8) Run it
```
make run
```
* Added dashboards to monitor the trickster and to test the trickster datasource (monitoring/grafana/dashboards/TricksterStatus.json & monitoring/grafana/dashboards/DockerMonitorinTrickster.json)
</details>
<details><summary>Homework 21 (logging-1)</summary>

### Task 1 - * (Parsing)
1) We can devide the grok pattern into 2 parts
```
<grok>
    pattern service=%{WORD:service} \| event=%{WORD:event} \| request_id=%{GREEDYDATA:request_id} \| message='%{GREEDYDATA:message}'
  </grok>
  <grok>
    pattern service=%{WORD:service} \| event=%{WORD:event} \| path=%{URIPATH:path} \| request_id=%{GREEDYDATA:request_id} \| remote_addr=%{IP:remote_addr} \| method= %{WORD:message} \| response_status=%{INT:response_status}
  </grok>
```
2) It remains to rebuild the image and check
```
make docker_build_fluentd
make run_logging
```
### Task 2 - * (Bugged application)
1) The first problem I encountered was a long post loading and the error that there is a problem with the comment service. Let's see what zipkin writes.
```
Client Start
Start Time	05/30 19:49:42.848_007
Relative Time	3.061s
Address	192.168.48.5:9292 (ui_app)

Client Finish
Start Time	05/30 19:50:12.967_778
Relative Time	33.180s
Address	192.168.48.5:9292 (ui_app)

Tags
error - 500
http.path - /5ed26aa51f9dce00140f9416/comments
http.status - 500

Server Address
192.168.48.2:9292 (comment)

Site displays - Can't show comments, some problems with the comment service
```
2) The problem turned out to be that variables are not declared in the comment service Dockerfile. Declare them in docker-compose.yml
```
comment:
    image: ${USERNAME}/comment:${COMMENT_VER}
    container_name: comment
    environment:
      - ZIPKIN_ENABLED=${ZIPKIN_ENABLED}
      - COMMENT_DATABASE_HOST=comment_db
      - COMMENT_DATABASE=comment
    networks:
      - front_net
      - back_net
```
3) After that, the problem went away, but a new one appeared, posts did not load fast enough. Let's see what zipkin writes.
```
POST
Client Start
Start Time	05/30 19:56:35.251_840
Relative Time	1.716ms
Address	192.168.48.5:9292 (ui_app)

Server Start
Start Time	05/30 19:56:35.254_037
Relative Time	3.913ms
Address	192.168.48.4:5000 (post)

Server Finish
Start Time	05/30 19:56:38.265_850
Relative Time	3.016s
Address	192.168.48.4:5000 (post)

Client Finish
Start Time	05/30 19:56:38.286_009
Relative Time	3.036s
Address	192.168.48.5:9292 (ui_app)

COMMENT
Client Start
Start Time	05/30 19:56:38.286_379
Relative Time	3.036s
Address	192.168.48.5:9292 (ui_app)

Client Finish
Start Time	05/30 19:56:38.304_208
Relative Time	3.054s
Address	192.168.48.5:9292 (ui_app)
```
* Everywhere a delay of at least 3 seconds, which is suspicious
4) We find the problem in the /post-py/post_app.py file, someone set a delay of 3 seconds in the find_post (id) block
```
def find_post(id):
...
        time.sleep(3)
...
```
* Delete or comment out this line
5) It remains to rebuild the image and restart the application
```
make docker_build_post_bug
make stop_app
make run_app
```
6) No more problems!
</details>
<details><summary>Homework 22 (kubernetes-1)</summary>

### Task 1 - Kubernetes The Hard Way
1) By default, if you have a google cloud platform account with a trial period, you cannot use more than four external IP addresses
Therefore, it is necessary to carefully check the commands before entering and edit them where necessary, so that the total number of instances does not exceed four
<details><summary>All executable commands that had to be edited here</summary>

```
for i in 0 1; do
  gcloud compute instances create controller-${i} \
    --async \
    --boot-disk-size 200GB \
    --can-ip-forward \
    --image-family ubuntu-1804-lts \
    --image-project ubuntu-os-cloud \
    --machine-type n1-standard-1 \
    --private-network-ip 10.240.0.1${i} \
    --scopes compute-rw,storage-ro,service-management,service-control,logging-write,monitoring \
    --subnet kubernetes \
    --tags kubernetes-the-hard-way,controller
done

for i in 0 1; do
  gcloud compute instances create worker-${i} \
    --async \
    --boot-disk-size 200GB \
    --can-ip-forward \
    --image-family ubuntu-1804-lts \
    --image-project ubuntu-os-cloud \
    --machine-type n1-standard-1 \
    --metadata pod-cidr=10.200.${i}.0/24 \
    --private-network-ip 10.240.0.2${i} \
    --scopes compute-rw,storage-ro,service-management,service-control,logging-write,monitoring \
    --subnet kubernetes \
    --tags kubernetes-the-hard-way,worker
done
-
for instance in worker-0 worker-1; do
cat > ${instance}-csr.json <<EOF
{
  "CN": "system:node:${instance}",
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "US",
      "L": "Portland",
      "O": "system:nodes",
      "OU": "Kubernetes The Hard Way",
      "ST": "Oregon"
    }
  ]
}
EOF

EXTERNAL_IP=$(gcloud compute instances describe ${instance} \
  --format 'value(networkInterfaces[0].accessConfigs[0].natIP)')

INTERNAL_IP=$(gcloud compute instances describe ${instance} \
  --format 'value(networkInterfaces[0].networkIP)')

cfssl gencert \
  -ca=ca.pem \
  -ca-key=ca-key.pem \
  -config=ca-config.json \
  -hostname=${instance},${EXTERNAL_IP},${INTERNAL_IP} \
  -profile=kubernetes \
  ${instance}-csr.json | cfssljson -bare ${instance}
done
-
{

KUBERNETES_PUBLIC_ADDRESS=$(gcloud compute addresses describe kubernetes-the-hard-way \
  --region $(gcloud config get-value compute/region) \
  --format 'value(address)')

KUBERNETES_HOSTNAMES=kubernetes,kubernetes.default,kubernetes.default.svc,kubernetes.default.svc.cluster,kubernetes.svc.cluster.local

cat > kubernetes-csr.json <<EOF
{
  "CN": "kubernetes",
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "US",
      "L": "Portland",
      "O": "Kubernetes",
      "OU": "Kubernetes The Hard Way",
      "ST": "Oregon"
    }
  ]
}
EOF

cfssl gencert \
  -ca=ca.pem \
  -ca-key=ca-key.pem \
  -config=ca-config.json \
  -hostname=10.32.0.1,10.240.0.10,10.240.0.11,${KUBERNETES_PUBLIC_ADDRESS},127.0.0.1,${KUBERNETES_HOSTNAMES} \
  -profile=kubernetes \
  kubernetes-csr.json | cfssljson -bare kubernetes

}
---
for instance in worker-0 worker-1; do
  sudo gcloud compute scp ca.pem ${instance}-key.pem ${instance}.pem ${instance}:~/
done
---
for instance in controller-0 controller-1; do
  sudo gcloud compute scp ca.pem ca-key.pem kubernetes-key.pem kubernetes.pem \
    service-account-key.pem service-account.pem ${instance}:~/
done
---
for instance in worker-0 worker-1; do
  kubectl config set-cluster kubernetes-the-hard-way \
    --certificate-authority=ca.pem \
    --embed-certs=true \
    --server=https://${KUBERNETES_PUBLIC_ADDRESS}:6443 \
    --kubeconfig=${instance}.kubeconfig

  kubectl config set-credentials system:node:${instance} \
    --client-certificate=${instance}.pem \
    --client-key=${instance}-key.pem \
    --embed-certs=true \
    --kubeconfig=${instance}.kubeconfig

  kubectl config set-context default \
    --cluster=kubernetes-the-hard-way \
    --user=system:node:${instance} \
    --kubeconfig=${instance}.kubeconfig

  kubectl config use-context default --kubeconfig=${instance}.kubeconfig
done
--
for instance in worker-0 worker-1; do
  sudo gcloud compute scp ${instance}.kubeconfig kube-proxy.kubeconfig ${instance}:~/
done
--
for instance in controller-0 controller-1; do
  sudo gcloud compute scp admin.kubeconfig kube-controller-manager.kubeconfig kube-scheduler.kubeconfig ${instance}:~/
done
--
for instance in controller-0 controller-1; do
  sudo gcloud compute scp encryption-config.yaml ${instance}:~/
done
--
cat <<EOF | sudo tee /etc/systemd/system/kube-apiserver.service
[Unit]
Description=Kubernetes API Server
Documentation=https://github.com/kubernetes/kubernetes

[Service]
ExecStart=/usr/local/bin/kube-apiserver \\
  --advertise-address=${INTERNAL_IP} \\
  --allow-privileged=true \\
  --apiserver-count=2 \\
  --audit-log-maxage=30 \\
  --audit-log-maxbackup=3 \\
  --audit-log-maxsize=100 \\
  --audit-log-path=/var/log/audit.log \\
  --authorization-mode=Node,RBAC \\
  --bind-address=0.0.0.0 \\
  --client-ca-file=/var/lib/kubernetes/ca.pem \\
  --enable-admission-plugins=NamespaceLifecycle,NodeRestriction,LimitRanger,ServiceAccount,DefaultStorageClass,ResourceQuota \\
  --etcd-cafile=/var/lib/kubernetes/ca.pem \\
  --etcd-certfile=/var/lib/kubernetes/kubernetes.pem \\
  --etcd-keyfile=/var/lib/kubernetes/kubernetes-key.pem \\
  --etcd-servers=https://10.240.0.10:2379,https://10.240.0.11:2379 \\
  --event-ttl=1h \\
  --encryption-provider-config=/var/lib/kubernetes/encryption-config.yaml \\
  --kubelet-certificate-authority=/var/lib/kubernetes/ca.pem \\
  --kubelet-client-certificate=/var/lib/kubernetes/kubernetes.pem \\
  --kubelet-client-key=/var/lib/kubernetes/kubernetes-key.pem \\
  --kubelet-https=true \\
  --runtime-config=api/all \\
  --service-account-key-file=/var/lib/kubernetes/service-account.pem \\
  --service-cluster-ip-range=10.32.0.0/24 \\
  --service-node-port-range=30000-32767 \\
  --tls-cert-file=/var/lib/kubernetes/kubernetes.pem \\
  --tls-private-key-file=/var/lib/kubernetes/kubernetes-key.pem \\
  --v=2
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
---
{
  KUBERNETES_PUBLIC_ADDRESS=$(gcloud compute addresses describe kubernetes-the-hard-way \
    --region $(gcloud config get-value compute/region) \
    --format 'value(address)')

  gcloud compute http-health-checks create kubernetes \
    --description "Kubernetes Health Check" \
    --host "kubernetes.default.svc.cluster.local" \
    --request-path "/healthz"

  gcloud compute firewall-rules create kubernetes-the-hard-way-allow-health-check \
    --network kubernetes-the-hard-way \
    --source-ranges 209.85.152.0/22,209.85.204.0/22,35.191.0.0/16 \
    --allow tcp

  gcloud compute target-pools create kubernetes-target-pool \
    --http-health-check kubernetes

  gcloud compute target-pools add-instances kubernetes-target-pool \
   --instances controller-0,controller-1

  gcloud compute forwarding-rules create kubernetes-forwarding-rule \
    --address ${KUBERNETES_PUBLIC_ADDRESS} \
    --ports 6443 \
    --region $(gcloud config get-value compute/region) \
    --target-pool kubernetes-target-pool
}
--
sudo gcloud compute ssh controller-0 \
  --command "kubectl get nodes --kubeconfig admin.kubeconfig"
--
for instance in worker-0 worker-1; do
  gcloud compute instances describe ${instance} \
    --format 'value[separator=" "](networkInterfaces[0].networkIP,metadata.items[0].value)'
done
--
for i in 0 1; do
  gcloud compute routes create kubernetes-route-10-200-${i}-0-24 \
    --network kubernetes-the-hard-way \
    --next-hop-address 10.240.0.2${i} \
    --destination-range 10.200.${i}.0/24
done
--
sudo gcloud compute ssh controller-0 \
  --command "sudo ETCDCTL_API=3 etcdctl get \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/etcd/ca.pem \
  --cert=/etc/etcd/kubernetes.pem \
  --key=/etc/etcd/kubernetes-key.pem\
  /registry/secrets/default/kubernetes-the-hard-way | hexdump -C"
--
gcloud -q compute instances delete \
  controller-0 controller-1 \
  worker-0 worker-1 \
  --zone $(gcloud config get-value compute/zone)
--
{
  gcloud -q compute routes delete \
    kubernetes-route-10-200-0-0-24 \
    kubernetes-route-10-200-1-0-24

  gcloud -q compute networks subnets delete kubernetes

  gcloud -q compute networks delete kubernetes-the-hard-way
}
```
</details>
2) Final result
```
NAME                                  READY   STATUS             RESTARTS   AGE
busybox                               1/1     Running            1          60m
comment-deployment-5664589dd9-kgqhm   1/1     Running            0          41m
mongo-deployment-86d49445c4-5qtxj     1/1     Running            0          8m6s
nginx-554b9c67f9-f6gmc                1/1     Running            0          4m12s
post-deployment-746d589f5f-7spc4      1/1     Running            0          42m
ui-deployment-778cdf9d5f-9pdqr        1/1     Running            0          6m14s
```

### Task 2 - Generate certs & Bootstrapping the etcd Cluster with Ansible
1) Generate certificates using a script /files/get-certs.sh and local ansible-playbook get-certs.yml
```
ansible-playbook --connection="local 127.0.0.1" playbooks/gen-certs.yml
```
2) Bootstrapping the etcd Cluster
```
ansible-playbook playbooks/bootstrap-etcd.yml
```
</details>
<details><summary>Homework 24 (kubernetes-2)</summary>

### Task 1 - * (GKE deployment with Terraform + Kubernetes Dashboard)
1) MANAGE KUBERNETES WITH TERRAFORM - Provision a GKE Cluster (Google Cloud)
https://learn.hashicorp.com/terraform/kubernetes/provision-gke-cluster
* All files are on the way /kubernetes/terraform
2) Clone the following repository
```
git clone https://github.com/hashicorp/learn-terraform-provision-gke-cluster
```
3) Due to the limits of the trial account, we will change the number of nodes from 3 to 1
* File gke.tf
```
...
# GKE cluster
resource "google_container_cluster" "primary" {
  name     = "${var.project_id}-gke"
  location = var.region

  remove_default_node_pool = true
  initial_node_count       = 1
...
```
4) Do not forget to change terraform.tfvars
5) Initialize Terraform workspace
```
terraform init
```
6) Provision the GKE cluster
```
terraform apply
```
7) Configure kubectl
```
gcloud container clusters get-credentials docker-275315-gke --region europe-west3 --project MY_PROJECT
```
8) Deploy and access Kubernetes Dashboard
```
kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.0.0-beta8/aio/deploy/recommended.yaml
```
9) Create a proxy server that will allow you to navigate to the dashboard
```
kubectl proxy
curl http://127.0.0.1:8001/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/
...
<head>
  <meta charset="utf-8">
  <title>Kubernetes Dashboard</title>
  <link rel="icon" type="image/png" href="assets/images/kubernetes-logo.png"/>
  <meta name="viewport" content="width=device-width">
<link rel="stylesheet" href="styles.dd2d1d3576191b87904a.css"></head>
...

```
10) Authenticate to Kubernetes Dashboard
```
kubectl apply -f https://raw.githubusercontent.com/hashicorp/learn-terraform-provision-eks-cluster/master/kubernetes-dashboard-admin.rbac.yaml
```
11) Generate the authorization token
```
kubectl -n kube-system describe secret $(kubectl -n kube-system get secret | grep service-controller-token | awk '{print $1}')
```
* Output
```
Data
====
namespace:  11 bytes
token:      eyJhbGciOiJSUzI1NiIsImtpZCI6IiJ9.eyJpc3MiOiJrdWJlcm5ldGVzL3NlcnZpY2VhY2Nv...
ca.crt:     1119 bytes
```

</details>
