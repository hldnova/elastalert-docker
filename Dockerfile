# Docker image for elastalert on Ubuntu Linux.

FROM ubuntu:xenial

MAINTAINER Lida He, https://github.com/hldnova

ENV ELASTALERT_VERSION v0.1.12
ENV ELASTALERT_PACKAGE https://github.com/Yelp/elastalert/archive/${ELASTALERT_VERSION}.zip

ENV ELASTALERT_HOME /opt/elastalert
ENV SUPERVISOR_CONF ${ELASTALERT_HOME}/elastalert_supervisord.conf
ENV ELASTALERT_CONFIG ${ELASTALERT_HOME}/config/elastalert_config.yaml

# Install software required for Elastalert
RUN apt update && \
    apt install -y --no-install-recommends \
        ca-certificates openssl libffi-dev libssl-dev gcc \
        python-dev python-pip python-setuptools \
        wget snmp less unzip busybox && \

# Link to busy box
    ln -s /bin/busybox /bin/ping && \
    ln -s /bin/busybox /bin/netstat && \
    ln -s /bin/busybox /usr/bin/vi && \

# Install smtp client
    echo "postfix postfix/mailname string localhost" | debconf-set-selections &&\
    echo "postfix postfix/main_mailer_type string 'Internet Site'" | debconf-set-selections &&\
    apt install -y mailutils --no-install-recommends && \

# Clean up
    rm -rf /var/cache/apt/* && rm -rf /var/lib/apt/lists/* && rm -rf ~/.cache && rm -rf /usr/share/doc

WORKDIR /opt
RUN wget ${ELASTALERT_PACKAGE} && \
    unzip *.zip && \
    rm *.zip && \
    mv elastalert* ${ELASTALERT_HOME}

WORKDIR ${ELASTALERT_HOME}

# Install Elastalert.
RUN python setup.py install && \
    pip install -e . && \
    pip uninstall twilio --yes && \
    pip install twilio==6.0.0 && \

# Install Supervisor.
    easy_install supervisor && \

# Copy default configuration files to configuration directory.
    cp ${ELASTALERT_HOME}/supervisord.conf.example ${SUPERVISOR_CONF} && \

# Elastalert Supervisor configuration:
    sed -i -e"s|logfile=.*log|logfile=${LOG_DIR}/elastalert_supervisord.log|g" ${SUPERVISOR_CONF} && \
    sed -i -e"s|stderr_logfile=.*log|stderr_logfile=${LOG_DIR}/elastalert_stderr.log|g" ${SUPERVISOR_CONF} && \
    sed -i -e"s|python elastalert.py|python -m elastalert.elastalert --config ${ELASTALERT_CONFIG}|g" ${SUPERVISOR_CONF} && \

# Clean up.
    rm -rf /var/cache/apt/* && rm -rf /var/lib/apt/lists/* && rm -rf ~/.cache && rm -rf /usr/share/doc
#    apt remove -y python-dev && \
#    apt remove -y gcc && \
#    apt remove -y libssl-dev && \
#    apt remove -y libffi-dev

# Entrypoint script
COPY ./entrypoint.sh /opt

# Make the start-script executable.
RUN chmod +x /opt/entrypoint.sh 

ENV TERM linux

CMD ["/opt/entrypoint.sh"]
