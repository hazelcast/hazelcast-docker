#!/bin/sh

PRG="$0"
PRGDIR=`dirname "$PRG"`
HAZELCAST_HOME=`cd "$PRGDIR/.." >/dev/null; pwd`/hazelcast
PID_FILE=$HAZELCAST_HOME/hazelcast_instance.pid

if [ "x$MIN_HEAP_SIZE" != "x" ]; then
	JAVA_OPTS="$JAVA_OPTS -Xms${MIN_HEAP_SIZE}"
fi

if [ "x$MAX_HEAP_SIZE" != "x" ]; then
	JAVA_OPTS="$JAVA_OPTS -Xmx${MAX_HEAP_SIZE}"
fi

export CLASSPATH=$HAZELCAST_HOME/hazelcast-all-$HZ_VERSION.jar:$HAZELCAST_HOME/jackson-annotations-2.6.0.jar:$HAZELCAST_HOME/jackson-core-2.6.3.jar:$HAZELCAST_HOME/jackson-databind-2.6.3.jar:$HAZELCAST_HOME/jackson-dataformat-yaml-2.6.3.jar:$HAZELCAST_HOME/jackson-module-jaxb-annotations-2.6.3.jar:$HAZELCAST_HOME/hazelcast-kubernetes-discovery-0.9.2.jar:$HAZELCAST_HOME/dnsjava-2.1.7.jar:$HAZELCAST_HOME/kubernetes-client-1.3.66.jar:$HAZELCAST_HOME/kubernetes-model-1.0.40.jar:$HAZELCAST_HOME/logging-interceptor-2.7.0.jar:$HAZELCAST_HOME/okhttp-2.7.0.jar:$HAZELCAST_HOME/okhttp-ws-2.7.0.jar:$HAZELCAST_HOME/okio-1.6.0.jar:$HAZELCAST_HOME/validation-api-1.1.0.Final.jar:$HAZELCAST_HOME/jul-to-slf4j-1.7.12.jar:$HAZELCAST_HOME/slf4j-api-1.7.12.jar:$HAZELCAST_HOME/snakeyaml-1.15.jar:$HAZELCAST_HOME/cache-api-1.0.0.jar:$CLASSPATH/*

echo "########################################"
echo "# RUN_JAVA=$RUN_JAVA"
echo "# JAVA_OPTS=$JAVA_OPTS"
echo "# starting now...."
echo "########################################"

echo "Process id for hazelcast instance is written to location: " $PID_FILE
java -server $JAVA_OPTS -Djava.net.preferIPv4Stack=true com.hazelcast.core.server.StartServer &
echo $! > ${PID_FILE}
sleep infinity
