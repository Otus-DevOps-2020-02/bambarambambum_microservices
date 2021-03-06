USER_NAME=androsovm

all: docker_build_ui docker_build_comment docker_build_post docker_build_prometheus docker_build_mongoexporter docker_build_blackbox docker_build_alertmanager docker_build_telegraf docker_build_grafana docker_build_stackdriver docker_build_trickster \
     docker_push_ui docker_push_comment docker_push_post docker_push_prometheus docker_push_blackbox docker_push_mongoexporter docker_push_alertmanager docker_push_telegraf docker_push_grafana docker_push_trickster docker_push_fluentd

build_all: docker_build_ui docker_build_comment docker_build_post docker_build_prometheus docker_build_mongoexporter docker_build_blackbox docker_build_alertmanager \
           docker_build_telegraf docker_build_grafana docker_build_stackdriver docker_build_trickster docker_build_fluentd

push_all: docker_push_ui docker_push_comment docker_push_post docker_push_prometheus docker_push_blackbox docker_push_mongoexporter docker_push_alertmanager \
          docker_push_telegraf docker_push_grafana docker_push_trickster docker_push_fluentd

run:
	docker-compose up -d && docker-compose -f docker-compose-monitoring.yml up -d && docker-compose -f docker-compose-loggin.yml up -d

run_monitoring:
	docker-compose -f docker-compose-monitoring.yml up -d

run_logging:
	docker-compose -f docker-compose-logging.yml up -d

run_app:
	docker-compose up -d

stop:
	docker-compose down && docker-compose -f docker-compose-monitoring.yml down && docker-compose -f docker-compose-logging.yml down

stop_monitoring:
	docker-compose -f docker-compose-monitoring.yml down

stop_logging:
	docker-compose -f docker-compose-logging.yml down

stop_app:
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

docker_build_trickster:
	cd ../monitoring/trickster && docker build -t ${USER_NAME}/trickster .

docker_build_fluentd:
	cd ../logging/fluentd && docker build -t ${USER_NAME}/fluentd .

docker_build_comment_bug:
	cd ../src/bugged-code/comment && bash docker_build.sh

docker_build_post_bug:
	cd ../src/bugged-code/post-py && bash docker_build.sh

docker_build_ui_bug:
	cd ../src/bugged-code/ui && bash docker_build.sh

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

docker_push_trickster:
	docker push ${USER_NAME}/trickster

docker_push_fluentd:
	docker push ${USER_NAME}/fluentd
