#!/bin/sh

PRG="$0"
PRGDIR=`dirname "$PRG"`
HAZELCAST_HOME=`cd "$PRGDIR/.." >/dev/null; pwd`/
PID_FILE=$HAZELCAST_HOME/hazelcast_instance.pid

if [ "x$MIN_HEAP_SIZE" != "x" ]; then
	JAVA_OPTS="$JAVA_OPTS -Xms${MIN_HEAP_SIZE}"
fi

if [ "x$MAX_HEAP_SIZE" != "x" ]; then
	JAVA_OPTS="$JAVA_OPTS -Xmx${MAX_HEAP_SIZE}"
fi

export CLASSPATH=$HAZELCAST_HOME/hazelcast-enterprise-$HZ_VERSION/lib/hazelcast-enterprise-all-$HZ_VERSION.jar

echo "########################################"
echo "# RUN_JAVA=$RUN_JAVA"
echo "# JAVA_OPTS=$JAVA_OPTS"
echo "# starting now...."
echo "########################################"
echo "Process id for hazelcast instance is written to location: " $PID_FILE
java -server $JAVA_OPTS -Djava.net.preferIPv4Stack=true -Dhazelcast.enterprise.license.key=$HZ_LICENSE_KEY com.hazelcast.core.server.StartServer &
echo $! > ${PID_FILE}

sleep infinity