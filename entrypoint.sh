#!/bin/sh

set -uxe

ES_PORT=${ELASTICSEARCH_PORT:-9200}
ES_HOST=${ELASTICSEARCH_HOST:-elasticsearch}

# 
for file in $(find /opt/elastalert -name '*.yaml' -or -name '*.yml')
do
    rm -f config_tmp
    cat $file | sed "s|es_host: [[:print:]]*|es_host: ${ES_HOST}|g" | sed "s|es_port: [[:print:]]*|es_port: ${ES_PORT}|g" > config_tmp
    cat config_tmp > $file
done 
rm -f config_tmp


# Wait until Elasticsearch is online since otherwise Elastalert will fail.
rm -f temp_file
while ! wget -O temp_file ${ES_HOST}:${ES_PORT} 2>/dev/null
do
    echo "Waiting for Elasticsearch..."
    rm -f temp_file
    sleep 1
done
rm -f temp_file
sleep 5

# Create Elastalert index if it does not exist.
if ! wget -O temp_file ${ES_HOST}:${ES_PORT}/elastalert_status 2>/dev/null
then
    echo "Creating Elastalert index in Elasticsearch..."
    elastalert-create-index --host ${ES_HOST} --port ${ES_PORT} --config ${ELASTALERT_CONFIG} --index elastalert_status --old-index ""
else
    echo "Elastalert index already exists in Elasticsearch."
fi
rm -f temp_file

# update hostname for postfix
sed -i "s|myhostname = [[:print:]]*|myhostname = $(hostname -f)|" /etc/postfix/main.cf

echo "Start smtp client"
service postfix start

echo "Starting Elastalert..."
exec supervisord -c ${SUPERVISOR_CONF} -n
