FROM registry.access.redhat.com/rhel7
MAINTAINER Hazelcast, Inc. Integration Team <info@hazelcast.com>

ENV HZ_HOME /opt/hazelcast/
ENV HZ_CP_MOUNT ${HZ_HOME}/external
ENV JAVA_HOME /usr/lib/jvm/java
ENV LANG en_US.utf8

ENV USER_NAME=hazelcast
ENV USER_UID=10001

ARG HZ_VERSION=3.8-RC1
ARG HZ_KUBE_VERSION=0.9.3
ARG HZ_MAVEN_DIR=${HZ_VERSION}
ARG REPOSITORY_URL=https://repo1.maven.org/maven2

LABEL name="hazelcast/hazelcast-openshift-rhel" \
      vendor="Hazelcast, Inc." \
      version="7.2" \
      architecture="x86_64" \
      release="${HZ_VERSION}" \
      url="http://www.hazelcast.com" \
      summary="Hazelcast Openshift Image, certified to RHEL 7" \
      description="Starts a standalone Hazelcast server instance to form a cluster based on kubernetes discovery inside Openshift" \
      io.k8s.description="Starts a standalone Hazelcast server instance to form a cluster based on kubernetes discovery inside Openshift" \
      io.k8s.display-name="Hazelcast" \
      io.openshift.expose-services="5701:tcp" \
      io.openshift.tags="hazelcast,java8,kubernetes,rhel7"

### User root while setup
USER root

RUN mkdir -p $HZ_HOME
RUN mkdir -p $HZ_CP_MOUNT 
WORKDIR $HZ_HOME

### Adding Hazelcast
ADD ${REPOSITORY_URL}/com/hazelcast/hazelcast-all/${HZ_MAVEN_DIR}/hazelcast-all-${HZ_VERSION}.jar $HZ_HOME

### Adding Logging redirector
ADD https://repo1.maven.org/maven2/org/slf4j/jul-to-slf4j/1.7.12/jul-to-slf4j-1.7.12.jar $HZ_HOME

### Adding JCache 
ADD https://repo1.maven.org/maven2/javax/cache/cache-api/1.0.0/cache-api-1.0.0.jar $HZ_HOME
 
ADD hazelcast.xml $HZ_HOME/hazelcast.xml
ADD start.sh $HZ_HOME/start.sh
ADD stop.sh $HZ_HOME/stop.sh
ADD healthcheck.sh $HZ_HOME/healthcheck.sh

### Atomic Help File
COPY help.md /tmp/

RUN yum clean all && \
    yum-config-manager --disable \* && \
### Add necessary Red Hat repos here
    yum-config-manager --enable rhel-7-server-rpms,rhel-7-server-optional-rpms,rhel-7-server-thirdparty-oracle-java-rpms && \
    yum -y update-minimal --security --sec-severity=Important --sec-severity=Critical --setopt=tsflags=nodocs && \
### Install Oracle Java 8
    yum -y install --setopt=tsflags=nodocs java-1.8.0-oracle-devel && \
### help markdown to man conversion
### Add your package needs to this installation line
    yum -y install --setopt=tsflags=nodocs golang-github-cpuguy83-go-md2man && \
    go-md2man -in /tmp/help.md -out /help.1 && \
    yum -y remove golang-github-cpuguy83-go-md2man && \
    yum -y clean all

### Configure Hazelcast
RUN useradd -l -u $USER_UID -r -g 0 -d $HZ_HOME -s /sbin/nologin -c "${USER_UID} application user" $USER_NAME
RUN chown -R $USER_UID:0 $HZ_HOME
RUN chown -R $USER_UID:0 $HZ_CP_MOUNT
RUN chmod +x $HZ_HOME/start.sh
RUN chmod +x $HZ_HOME/stop.sh
RUN chmod +x $HZ_HOME/healthcheck.sh

### Adding maven wrapper, downloading Hazelcast Kubernetes discovery plugin and dependencies and cleaning up
COPY mvnw $HZ_HOME/mvnw
RUN cd mvnw && \
    chmod +x mvnw && \
    ./mvnw -f dependency-copy.xml -Dhazelcast-kubernetes-version=${HZ_KUBE_VERSION} dependency:copy-dependencies && \
    cd .. && \
    rm -rf $HZ_HOME/mvnw && \
    rm -rf /root/.m2

### Switch to default user
USER $USER_UID

### Expose port
EXPOSE 5701

### Start hazelcast standalone server.
CMD ["/bin/sh", "-c", "./start.sh"]

