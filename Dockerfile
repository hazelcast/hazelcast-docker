FROM java:7
ENV HZVERSION 3.4.1
ENV HZ_HOME /opt/hazelcast/
RUN mkdir -p $HZ_HOME
WORKDIR $HZ_HOME
# Download hazelcast jars from enterprise repo.
ADD https://repository-hazelcast-l337.forge.cloudbees.com/release/com/hazelcast/hazelcast-enterprise/$HZVERSION/hazelcast-enterprise-$HZVERSION.jar $HZ_HOME 
# Start hazelcast standalone server.
CMD java -server -cp hazelcast-enterprise-$HZVERSION.jar -Dhazelcast.enterprise.license.key=$HZ_LICENSE_KEY com.hazelcast.core.server.StartServer
