ENV HZ_VERSION 3.5.3
ENV HZ_VERSION 3.5.2
ENV HZ_HOME /opt/hazelcast/
RUN mkdir -p $HZ_HOME
WORKDIR $HZ_HOME
# Download hazelcast jars from maven repo.
ADD http://download.hazelcast.com/download.jsp?version=hazelcast-$HZ_VERSION&p=docker $HZ_HOME/hazelcast.zip
RUN unzip hazelcast.zip
WORKDIR $HZ_HOME/hazelcast-$HZ_VERSION/mancenter
CMD sh startManCenter.sh
EXPOSE 8080
