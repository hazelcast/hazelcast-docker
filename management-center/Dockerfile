FROM java:7-jre
ENV HZ_VERSION 3.8.2
ENV HZ_HOME /opt/hazelcast/
# Persistent VOLUME definitions
ENV MANCENTER_DATA /data
VOLUME ["/data"]

RUN mkdir -p $HZ_HOME
WORKDIR $HZ_HOME

# Download Hazelcast distribution
ADD http://download.hazelcast.com/download.jsp?version=hazelcast-$HZ_VERSION&p=docker $HZ_HOME/hazelcast.zip
RUN unzip hazelcast.zip
WORKDIR $HZ_HOME/hazelcast-$HZ_VERSION/mancenter
### Start Management Center standalone server.
COPY start.sh .
RUN chmod a+x start.sh
CMD ["/bin/sh", "-c", "./start.sh"]
EXPOSE 8080
