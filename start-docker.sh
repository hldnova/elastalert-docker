#!/bin/sh

NAME=elastalert-1
docker rm -f $NAME

docker run -d --name $NAME \
           -h $(hostname -f) \
           -e "ELASTICSEARCH_HOST=10.247.134.224" \
           -e "ELASTICSEARCH_PORT=9200" \
           -v $PWD/config/config.yaml:/opt/elastalert/elastalert_config.yaml \
           -v $PWD/rules/:/opt/elastalert/rules/ \
    elastalert
