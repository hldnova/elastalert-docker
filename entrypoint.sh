#!/bin/sh

set -xe

ES_HOST=${ELASTICSEARCH_HOST:-elasticsearch}
ES_PORT=${ELASTICSEARCH_PORT:-9200}

# update elastalert_config.yaml
CONFIG_TMP=${ELASTALERT_HOME}/config/config.yaml.template
cat $CONFIG_TMP | sed "s|es_host: [[:print:]]*|es_host: ${ES_HOST}|g" \
                | sed "s|es_port: [[:print:]]*|es_port: ${ES_PORT}|g" \
    > $ELASTALERT_CONFIG

# update rules
for rule_tmp in $(find /opt/elastalert/rules -name '*.template' )
do
    rule=`echo ${rule_tmp%.template}`.yaml

    cat $rule_tmp | sed "s|es_host: [[:print:]]*|es_host: ${ES_HOST}|g" \
                  | sed "s|es_port: [[:print:]]*|es_port: ${ES_PORT}|g" \
                  | sed "s|SLACK_WEBHOOK_URL|${SLACK_WEBHOOK_URL:-http://localhost}|" \
                  | sed "s|SNMP_COMMUNITY|${SNMP_COMMUNITYi:-public}|" \
                  | sed "s|SNMP_TRAP_DESTINATION|${SNMP_TRAP_DESTINATION:-localhost}|" \
                  | sed "s|EMAIL_ADDRESS|${EMAIL_ADDRESS:-root@localhost}|" \
                  | sed "s|KIBANA_URL|${KIBANA_URL:-'http://localhost:5601'}|" \
        > $rule
done 

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
