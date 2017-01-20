#!/usr/bin/env bash

SPARK_COMMON_OPTS="-Dcom.sun.management.jmxremote.port=6000 -Dcom.sun.management.jmxremote.ssl=false"
SPARK_COMMON_OPTS+=" -Dcom.sun.management.jmxremote.authenticate=false"

SPARK_MASTER_OPTS=$SPARK_COMMON_OPTS

SPARK_WORKER_OPTS="-Dspark.worker.cleanup.enabled=true ${SPARK_COMMON_OPTS}"

SPARK_DAEMON_JAVA_OPTS="-Djava.net.preferIPv4Stack=true"
SPARK_DAEMON_MEMORY=2g

SPARK_PID_DIR="${SPARK_HOME}/run"
