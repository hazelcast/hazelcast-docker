FROM hazelcast/hazelcast:3.7.1
ENV HZ_VERSION 3.7.1
ENV HZ_HOME /opt/hazelcast/
RUN mkdir -p $HZ_HOME
WORKDIR $HZ_HOME

#Jackson Dependencies
ADD https://repo1.maven.org/maven2/com/fasterxml/jackson/core/jackson-annotations/2.6.0/jackson-annotations-2.6.0.jar $HZ_HOME
ADD https://repo1.maven.org/maven2/com/fasterxml/jackson/core/jackson-core/2.6.3/jackson-core-2.6.3.jar $HZ_HOME
ADD https://repo1.maven.org/maven2/com/fasterxml/jackson/core/jackson-databind/2.6.3/jackson-databind-2.6.3.jar $HZ_HOME
ADD https://repo1.maven.org/maven2/com/fasterxml/jackson/dataformat/jackson-dataformat-yaml/2.6.3/jackson-dataformat-yaml-2.6.3.jar $HZ_HOME
ADD https://repo1.maven.org/maven2/com/fasterxml/jackson/module/jackson-module-jaxb-annotations/2.6.3/jackson-module-jaxb-annotations-2.6.3.jar $HZ_HOME

#Discovery Plugin
ADD https://repo1.maven.org/maven2/com/noctarius/discovery/hazelcast-kubernetes-discovery/0.9.3/hazelcast-kubernetes-discovery-0.9.3.jar $HZ_HOME

#DNS Java
ADD https://repo1.maven.org/maven2/dnsjava/dnsjava/2.1.7/dnsjava-2.1.7.jar $HZ_HOME

#Kubernetes Client
ADD https://repo1.maven.org/maven2/io/fabric8/kubernetes-client/1.3.66/kubernetes-client-1.3.66.jar $HZ_HOME
ADD https://repo1.maven.org/maven2/io/fabric8/kubernetes-model/1.0.40/kubernetes-model-1.0.40.jar $HZ_HOME

#Ok Http
ADD https://repo1.maven.org/maven2/com/squareup/okhttp/logging-interceptor/2.7.0/logging-interceptor-2.7.0.jar $HZ_HOME
ADD https://repo1.maven.org/maven2/com/squareup/okhttp/okhttp/2.7.0/okhttp-2.7.0.jar $HZ_HOME
ADD https://repo1.maven.org/maven2/com/squareup/okhttp/okhttp-ws/2.7.0/okhttp-ws-2.7.0.jar $HZ_HOME
ADD https://repo1.maven.org/maven2/com/squareup/okio/okio/1.6.0/okio-1.6.0.jar $HZ_HOME

#Logging and Validation
ADD https://repo1.maven.org/maven2/javax/validation/validation-api/1.1.0.Final/validation-api-1.1.0.Final.jar $HZ_HOME
ADD https://repo1.maven.org/maven2/org/slf4j/jul-to-slf4j/1.7.12/jul-to-slf4j-1.7.12.jar $HZ_HOME
ADD https://repo1.maven.org/maven2/org/slf4j/slf4j-api/1.7.12/slf4j-api-1.7.12.jar $HZ_HOME
ADD https://repo1.maven.org/maven2/org/yaml/snakeyaml/1.15/snakeyaml-1.15.jar $HZ_HOME

#JCache 
ADD https://repo1.maven.org/maven2/javax/cache/cache-api/1.0.0/cache-api-1.0.0.jar $HZ_HOME
 
ADD hazelcast.xml /$HZ_HOME/hazelcast.xml
ADD start.sh /$HZ_HOME/start.sh
ADD stop.sh /$HZ_HOME/stop.sh

RUN chmod 777 /$HZ_HOME/start.sh
RUN chmod 777 /$HZ_HOME/stop.sh
# Start hazelcast standalone server.
CMD ./start.sh
EXPOSE 5701

