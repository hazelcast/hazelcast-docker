FROM openjdk:8u151-jre-alpine
ENV HZ_VERSION 3.9.2
ENV HZ_HOME /opt/hazelcast/
# provide bash
RUN apk update
RUN apk upgrade
RUN apk add bash
RUN mkdir -p $HZ_HOME
WORKDIR $HZ_HOME
# Download hazelcast jars from maven repo.
ADD http://download.hazelcast.com/enterprise/hazelcast-enterprise-$HZ_VERSION.zip $HZ_HOME/hazelcast.zip
RUN unzip hazelcast.zip
# Adding JCache
ADD https://repo1.maven.org/maven2/javax/cache/cache-api/1.0.0/cache-api-1.0.0.jar $HZ_HOME
ADD server.sh /$HZ_HOME/server.sh
ADD stop.sh /$HZ_HOME/stop.sh
RUN chmod +x /$HZ_HOME/server.sh
RUN chmod +x /$HZ_HOME/stop.sh
# Start hazelcast standalone server.
CMD ["./server.sh"]
