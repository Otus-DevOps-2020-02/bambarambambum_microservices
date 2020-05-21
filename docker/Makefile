USER_NAME=androsovm

all: docker_build_ui docker_build_comment docker_build_post docker_build_prometheus docker_build_mongoexporter docker_build_blackbox \
     docker_push_ui docker_push_comment docker_push_post docker_push_prometheus docker_push_blackbox docker_push_mongoexporter

build_all: docker_build_ui docker_build_comment docker_build_post docker_build_prometheus docker_build_mongoexporter docker_build_blackbox

push_all: docker_push_ui docker_push_comment docker_push_post docker_push_prometheus docker_push_blackbox docker_push_mongoexporter

docker_build_ui:
	cd ../src/ui && ./docker_build.sh

docker_build_comment:
	cd ../src/comment && ./docker_build.sh

docker_build_post:
	cd ../src/post-py && ./docker_build.sh

docker_build_prometheus:
	cd ../monitoring/prometheus && docker build -t ${USER_NAME}/prometheus .

docker_build_blackbox:
	cd ../monitoring/blackbox && docker build -t ${USER_NAME}/blackbox-exporter:1.0 .

docker_build_mongoexporter:
	cd ../../mongodb_exporter && docker build -t ${USER_NAME}/mongodb-exporter:1.0 .

docker_push_ui:
	docker push ${USER_NAME}/ui

docker_push_comment:
	docker push ${USER_NAME}/comment

docker_push_post:
	docker push ${USER_NAME}/post

docker_push_prometheus:
	docker push ${USER_NAME}/prometheus

docker_push_blackbox:
	docker push ${USER_NAME}/blackbox-exporter:1.0

docker_push_mongoexporter:
	docker push ${USER_NAME}/mongodb-exporter:1.0
