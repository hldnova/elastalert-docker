#!/bin/sh

NAME=elastalert
docker rm -f $NAME

docker run -d --name $NAME \
           -h $(hostname -f) \
           -e "ELASTICSEARCH_HOST=elasticsearch" \
           -e "ELASTICSEARCH_PORT=9200" \
           -e "EMAIL_ADDRESS=root@localhost" \
           -v $PWD/config/config.yaml:/opt/elastalert/elastalert_config.yaml \
           -v $PWD/rules/:/opt/elastalert/rules/ \
    emccorp/docker-elastalert:0.1.12
