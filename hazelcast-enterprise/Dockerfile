FROM java:7-jre
ENV HZ_VERSION 3.7.4
ENV HZ_HOME /opt/hazelcast/
RUN mkdir -p $HZ_HOME
WORKDIR $HZ_HOME
# Download hazelcast jars from maven repo.
ADD http://download.hazelcast.com/enterprise/hazelcast-enterprise-$HZ_VERSION.zip $HZ_HOME/hazelcast.zip
RUN unzip hazelcast.zip
ADD server.sh /$HZ_HOME/server.sh
ADD stop.sh /$HZ_HOME/stop.sh
RUN chmod +x /$HZ_HOME/server.sh
RUN chmod +x /$HZ_HOME/stop.sh
# Start hazelcast standalone server.
CMD ["./server.sh"]