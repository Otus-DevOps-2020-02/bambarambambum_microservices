USER_NAME=androsovm

all: docker_build_ui docker_build_comment docker_build_post docker_build_prometheus docker_build_mongoexporter docker_build_blackbox docker_build_alertmanager docker_build_telegraf docker_build_grafana docker_build_stackdriver \
     docker_push_ui docker_push_comment docker_push_post docker_push_prometheus docker_push_blackbox docker_push_mongoexporter docker_push_alertmanager docker_push_telegraf docker_push_grafana

build_all: docker_build_ui docker_build_comment docker_build_post docker_build_prometheus docker_build_mongoexporter docker_build_blackbox docker_build_alertmanager docker_build_telegraf docker_build_grafana docker_build_stackdriver

push_all: docker_push_ui docker_push_comment docker_push_post docker_push_prometheus docker_push_blackbox docker_push_mongoexporter docker_push_alertmanager docker_push_telegraf docker_push_grafana

run:
	docker-compose up -d && docker-compose -f docker-compose-monitoring.yml up -d

run_monitoring:
	docker-compose -f docker-compose-monitoring.yml up -d

run_app:
	docker-compose up -d

stop:
	docker-compose down && docker-compose -f docker-compose-monitoring.yml down

stop_monitoring:
	docker-compose -f docker-compose-monitoring.yml down

stop_up:
	docker-compose down

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

docker_build_alertmanager:
	cd ../monitoring/alertmanager && docker build -t ${USER_NAME}/alertmanager .

docker_build_telegraf:
	cd ../monitoring/telegraf && docker build -t ${USER_NAME}/telegraf .

docker_build_grafana:
	cd ../monitoring/grafana && docker build -t ${USER_NAME}/grafana .

docker_build_stackdriver:
	cd ../monitoring/stackdriver && docker build -t ${USER_NAME}/stackdriver .

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

docker_push_alertmanager:
	docker push ${USER_NAME}/alertmanager

docker_push_telegraf:
	docker push ${USER_NAME}/telegraf

docker_push_grafana:
	docker push ${USER_NAME}/grafana
