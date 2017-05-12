#!/bin/sh
set -uxe

NAME=elastalert
docker rm -f $NAME

docker run -d --name $NAME \
           -h $(hostname -f) \
           -e "ELASTICSEARCH_HOST=${ELASTICSEARCH_HOST:-elasticsearch}" \
           -e "ELASTICSEARCH_PORT=${ELASTICSEARCH_PORT:-9200}" \
           -e "EMAIL_ADDRESS=${EMAIL_ADDRESS:-root@localhost}" \
           -e "SLACK_WEBHOOK_URL=${SLACK_WEBHOOK_URL:-your-slack-webhook-url}" \
           -v $PWD/config/:/opt/elastalert/config/ \
           -v $PWD/rules/:/opt/elastalert/rules/ \
    emccorp/docker-elastalert:0.1.12
