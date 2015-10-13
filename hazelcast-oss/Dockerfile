ENV HZ_VERSION 3.5.3
ENV HZ_VERSION 3.5.2
ENV HZ_HOME /opt/hazelcast/
RUN mkdir -p $HZ_HOME
WORKDIR $HZ_HOME
# Download hazelcast jars from maven repo.
ADD https://repo1.maven.org/maven2/com/hazelcast/hazelcast-all/$HZ_VERSION/hazelcast-all-$HZ_VERSION.jar $HZ_HOME
# Start hazelcast standalone server.
CMD java -cp hazelcast-all-$HZ_VERSION.jar com.hazelcast.core.server.StartServer
EXPOSE 5701

