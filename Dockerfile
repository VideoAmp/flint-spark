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

ARG SPARK_BINARY_VERSION
ARG NATIVE_LIB_VERSION

# AWS cli is needed for refresh_na_26_db.sh script
RUN wget https://s3.amazonaws.com/aws-cli/awscli-bundle.zip
RUN unzip awscli-bundle.zip
RUN ./awscli-bundle/install -i /usr/local/aws -b /usr/local/bin/aws
RUN rm -rf awscli-bundle*

RUN wget -O /tmp/yjp.tgz https://s3.amazonaws.com/vamp-artifacts/yourkit/yjp-2017.02-b50-linux-min.tgz
RUN tar xzf /tmp/yjp.tgz -C /opt
RUN cd /opt && ln -s yjp-2017.02 yjp
RUN rm /tmp/yjp.tgz

RUN mkdir -p /opt/geo
COPY bin/refresh_na_26_db.sh /usr/local/bin/refresh_na_26_db.sh

RUN wget -O /tmp/hadoop-conf.zip http://prod-cdh-cm-01.prod.use1:7180/api/v11/clusters/Production%20US-EAST-1/services/hive/clientConfig
RUN unzip -d /tmp /tmp/hadoop-conf.zip
RUN cp /tmp/hive-conf/core-site.xml /opt/spark/conf
RUN cp /tmp/hive-conf/hdfs-site.xml /opt/spark/conf
RUN cp /tmp/hive-conf/hive-site.xml /opt/spark/conf

RUN mkdir -p /opt/spark/lib
RUN wget -O - https://s3.amazonaws.com/vamp-static/public/spark-native-libs/$NATIVE_LIB_VERSION/hadoop-libs.gz | tar xzf - -C /opt/spark/lib

RUN apk add jq lighttpd

RUN find /opt/spark/jars -name '*.jar' -exec sha256sum {} \; | jq --raw-input 'split("  /opt/spark/jars/") | {name: .[1], signature: .[0]}' | jq --slurp . > /opt/spark/jars/MANIFEST.json
RUN echo 'server.port = 8088' >> /etc/lighttpd/lighttpd.conf
RUN echo 'dir-listing.activate = "enable"' >> /etc/lighttpd/lighttpd.conf
COPY bootstrap/bootstrap.sc /var/www/localhost/htdocs
COPY setup/$SPARK_BINARY_VERSION /var/www/localhost/htdocs/setup/flint
RUN ln -s /opt/spark/jars /var/www/localhost/htdocs/jars
RUN ln -s /opt/spark/conf /var/www/localhost/htdocs/conf
