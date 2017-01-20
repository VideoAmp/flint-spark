FROM videoamp/alpine-java:8_jdk_unlimited

ARG DISTFILE

RUN apk update
RUN apk add ca-certificates procps python wget jemalloc

ENV R_PKG_RELEASE="3.3.1-r0"

RUN wget -O /etc/apk/keys/sgerrand.rsa.pub https://github.com/sgerrand/alpine-pkg-R/releases/download/${R_PKG_RELEASE}/sgerrand.rsa.pub
RUN wget -O /tmp/R-${R_PKG_RELEASE}.apk https://github.com/sgerrand/alpine-pkg-R/releases/download/${R_PKG_RELEASE}/R-${R_PKG_RELEASE}.apk
RUN apk add /tmp/R-${R_PKG_RELEASE}.apk
RUN rm /tmp/R-${R_PKG_RELEASE}.apk

EXPOSE 6000 7005 7006 7077 8080 8081 8088 8888

ENV SPARK_HOME="/opt/spark" \
    SPARK_WORKER_PORT=8888 \
    SPARK_LOCAL_DIRS="" \
    SPARK_WORKER_MEMORY="" \
    SPARK_MASTER_URL=""

ADD $DISTFILE /opt
RUN cd /opt && ln -s $(basename $DISTFILE .tgz) spark
COPY spark /opt/spark

# https://github.com/apache/spark/commit/c2c107abad8b462218d33c70b946e840663228a1 added "--" after
# the "nohup" command in spark-daemon.sh. BusyBox doesn't like that, so remove it.
RUN sed -i 's/nohup --/nohup/' /opt/spark/sbin/spark-daemon.sh

COPY boot/boot-master.sh /usr/local/sbin/boot-master.sh
COPY boot/boot-worker.sh /usr/local/sbin/boot-worker.sh
