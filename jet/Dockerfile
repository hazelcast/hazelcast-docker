FROM openjdk:8-jre
ENV JET_VERSION 0.5
ENV JET_HOME /opt/hazelcast-jet/
RUN mkdir -p $JET_HOME
WORKDIR $JET_HOME
# Download hazelcast-jet jars from maven repo.
ADD https://repo1.maven.org/maven2/com/hazelcast/jet/hazelcast-jet/$JET_VERSION/hazelcast-jet-$JET_VERSION.jar $JET_HOME
ADD server.sh /$JET_HOME/server.sh
ADD stop.sh /$JET_HOME/stop.sh
RUN chmod +x /$JET_HOME/server.sh
RUN chmod +x /$JET_HOME/stop.sh
# Start hazelcast standalone server.
CMD ["./server.sh"]
EXPOSE 5701
