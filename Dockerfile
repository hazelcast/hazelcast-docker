FROM centos:7
# Install java.. TODO: make it configuraable
RUN yum -y install java-1.7.0-openjdk-devel && yum clean all
ENV HZVERSION 3.4.1
ENV HZ_HOME /opt/hazelcast/
RUN mkdir -p HZ_HOME
WORKDIR $HZ_HOME
# Download hazelcast jars from maven repo.
ADD https://repo1.maven.org/maven2/com/hazelcast/hazelcast/$HZVERSION/hazelcast-$HZVERSION.jar $HZ_HOME
# Start hazelcast standalone server.
CMD java -server -cp $HZ_HOME/hazelcast-$HZVERSION.jar com.hazelcast.core.server.StartServer

