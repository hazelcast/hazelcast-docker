FROM centos:7
MAINTAINER Hazelcast, Inc. Integration Team <info@hazelcast.com>

ENV HZ_HOME /opt/hazelcast/
ENV HZ_CP_MOUNT ${HZ_HOME}/external
ENV JAVA_HOME /usr/lib/jvm/java
ENV LANG en_US.utf8

ENV USER_NAME=hazelcast
ENV USER_UID=10001

ENV HZ_VERSION 3.10.2

ARG HZ_KUBE_VERSION=1.1.0
ARG HZ_MAVEN_DIR=${HZ_VERSION}
ARG REPOSITORY_URL=https://repository-hazelcast-l337.forge.cloudbees.com/release

RUN mkdir -p $HZ_HOME
RUN mkdir -p $HZ_CP_MOUNT
WORKDIR $HZ_HOME

ADD hazelcast.xml $HZ_HOME/hazelcast.xml
ADD start.sh $HZ_HOME/start.sh
ADD stop.sh $HZ_HOME/stop.sh

RUN yum update -y && \
yum install -y wget && \
yum install -y java-1.8.0-openjdk && \
yum clean all

ENV JAVA_HOME /etc/alternatives/jre

### add hazelcast enterprise
ADD ${REPOSITORY_URL}/com/hazelcast/hazelcast-enterprise-all/${HZ_VERSION}/hazelcast-enterprise-all-${HZ_VERSION}.jar $HZ_HOME

### Adding Logging redirector
ADD https://repo1.maven.org/maven2/org/slf4j/jul-to-slf4j/1.7.12/jul-to-slf4j-1.7.12.jar $HZ_HOME

### Adding JCache
ADD https://repo1.maven.org/maven2/javax/cache/cache-api/1.0.0/cache-api-1.0.0.jar $HZ_HOME

### Adding maven wrapper, downloading Hazelcast Kubernetes discovery plugin and dependencies and cleaning up
ADD https://github.com/takari/maven-wrapper/archive/maven-wrapper-0.3.0.tar.gz $HZ_HOME
RUN cd $HZ_HOME && \
    tar zxf maven-wrapper*.tar.gz && \
    rm -fr maven-wrapper*.tar.gz && \
    mv maven-wrapper* mvnw
COPY mvnw $HZ_HOME/mvnw

### Configure Hazelcast
RUN useradd -l -u $USER_UID -r -g 0 -d $HZ_HOME -s /sbin/nologin -c "${USER_UID} application user" $USER_NAME
RUN chown -R $USER_UID:0 $HZ_HOME $HZ_CP_MOUNT
RUN chmod +x $HZ_HOME/*.sh

### Switch to hazelcast user
USER $USER_UID
RUN cd mvnw && \
    chmod +x mvnw && \
    sync && \
    ./mvnw -f dependency-copy.xml -Dhazelcast-kubernetes-version=${HZ_KUBE_VERSION} dependency:copy-dependencies && \
    cd .. && \
    rm -rf $HZ_HOME/mvnw && \
    rm -rf $HZ_HOME/.m2 && \
    chmod -R +r $HZ_HOME

### Expose port
EXPOSE 5701

### Start hazelcast standalone server.
CMD ["/bin/sh", "-c", "./start.sh"]
