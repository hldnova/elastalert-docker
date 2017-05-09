# Elastalert Docker image running on Alpine Linux.

FROM ubuntu:xenial

MAINTAINER Lida He, https://github.com/hldnova

ENV ELASTALERT_VERSION v0.1.12
ENV ELASTALERT_PACKAGE https://github.com/Yelp/elastalert/archive/${ELASTALERT_VERSION}.zip

ENV ELASTALERT_HOME /opt/elastalert
ENV SUPERVISOR_CONF ${ELASTALERT_HOME}/elastalert_supervisord.conf
ENV ELASTALERT_CONFIG ${ELASTALERT_HOME}/elastalert_config.yaml

# Install software required for Elastalert and NTP for time synchronization.
RUN apt update && \
    apt install -y --no-install-recommends \
        ca-certificates openssl libffi-dev libssl-dev gcc \
        python-dev python-pip python-setuptools \
        wget net-tools less unzip vim && \
    rm -rf /var/cache/apt/* 

# Install smtp client
RUN echo "postfix postfix/mailname string localhost" | debconf-set-selections &&\
    echo "postfix postfix/main_mailer_type string 'Internet Site'" | debconf-set-selections &&\
    apt-get install -y mailutils --no-install-recommends && \
    rm -rf /var/cache/apt/*

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

# Create directories. The /var/empty directory is used by openntpd.
#    mkdir -p ${CONFIG_DIR} && \
#    mkdir -p ${RULES_DIRECTORY} && \
#    mkdir -p ${LOG_DIR} && \
#    mkdir -p /var/empty && \

# Copy default configuration files to configuration directory.
    cp ${ELASTALERT_HOME}/supervisord.conf.example ${SUPERVISOR_CONF} && \

# Elastalert Supervisor configuration:
    # Redirect Supervisor log output to a file in the designated logs directory.
    sed -i -e"s|logfile=.*log|logfile=${LOG_DIR}/elastalert_supervisord.log|g" ${SUPERVISOR_CONF} && \
    # Redirect Supervisor stderr output to a file in the designated logs directory.
    sed -i -e"s|stderr_logfile=.*log|stderr_logfile=${LOG_DIR}/elastalert_stderr.log|g" ${SUPERVISOR_CONF} && \
    # Modify the start-command.
    sed -i -e"s|python elastalert.py|python -m elastalert.elastalert --config ${ELASTALERT_CONFIG}|g" ${SUPERVISOR_CONF} && \

# Clean up.
    apt remove -y python-dev && \
    apt remove -y gcc && \
    apt remove -y libssl-dev && \
    apt remove -y libffi-dev

# Add Elastalert to Supervisord.
#    supervisord -c ${ELASTALERT_SUPERVISOR_CONF}

# Copy the script used to launch the Elastalert when a container is started.
COPY ./entrypoint.sh /opt

# Make the start-script executable.
RUN chmod +x /opt/entrypoint.sh 

ENV TERM linux

# Define mount points.
#VOLUME [ "${CONFIG_DIR}", "${RULES_DIRECTORY}", "${LOG_DIR}"]

# Launch Elastalert when a container is started.
CMD ["/opt/entrypoint.sh"]
