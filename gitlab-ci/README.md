docker run -d --name gitlab-runner2 --restart always \
  -v /srv/gitlab-runner/config:/etc/gitlab-runner \
  -v /var/run/docker.sock:/var/run/docker.sock \
  gitlab/gitlab-runner:latest

docker exec gitlab-runner2 gitlab-runner register \
           --locked=false \
           --non-interactive \
           --url http://34.107.83.160/ \
           --registration-token v3aNxnjLdRzwYUpmf19e\
           --description "Docker Runner" \
           --tag-list "linux,xenial,ubuntu,docker" \
           --executor docker \
           --docker-image "alpine:latest" \
           --docker-volumes /var/run/docker.sock:/var/run/docker.sock
