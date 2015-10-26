FROM java:7
ENV HZ_VERSION 3.5.3
ENV HZ_HOME /opt/hazelcast/
RUN mkdir -p $HZ_HOME
WORKDIR $HZ_HOME
# Download hazelcast jars from ee download server.
ADD http://download.hazelcast.com/enterprise/hazelcast-enterprise-$HZ_VERSION.zip $HZ_HOME/hazelcast.zip
RUN unzip hazelcast.zip
# Start hazelcast standalone server.
WORKDIR $HZ_HOME/hazelcast-enterprise-$HZ_VERSION
ADD server.sh /$HZ_HOME/hazelcast-enterprise-$HZ_VERSION/server.sh
ADD stop.sh /$HZ_HOME/hazelcast-enterprise-$HZ_VERSION/stop.sh
RUN chmod +x /$HZ_HOME/hazelcast-enterprise-$HZ_VERSION/server.sh
RUN chmod +x /$HZ_HOME/hazelcast-enterprise-$HZ_VERSION/stop.sh
# Start hazelcast standalone server.
CMD ./server.sh
EXPOSE 5701