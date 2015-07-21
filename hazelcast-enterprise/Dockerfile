ENV HZ_VERSION 3.5
FROM java:7
ENV HZ_HOME /opt/hazelcast/
RUN mkdir -p $HZ_HOME
WORKDIR $HZ_HOME
# Download hazelcast jars from maven repo.
ADD http://download.hazelcast.com/enterprise/hazelcast-enterprise-$HZ_VERSION.zip $HZ_HOME/hazelcast.zip
RUN unzip hazelcast.zip
# Start hazelcast standalone server.
WORKDIR $HZ_HOME/hazelcast-enterprise-$HZ_VERSION
CMD java -server -Djava.net.preferIPv4Stack=true -Dhazelcast.enterprise.license.key=$HZ_LICENSE_KEY -cp lib/hazelcast-enterprise-all-$HZ_VERSION.jar com.hazelcast.core.server.StartServer
