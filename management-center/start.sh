#!/bin/sh

PRG="$0"
PRGDIR=`dirname "$PRG"`
HAZELCAST_HOME=`cd "$PRGDIR/.." >/dev/null; pwd`/hazelcast

if [ "x$MIN_HEAP_SIZE" != "x" ]; then
	JAVA_OPTS="$JAVA_OPTS -Xms${MIN_HEAP_SIZE}"
fi

if [ "x$MAX_HEAP_SIZE" != "x" ]; then
	JAVA_OPTS="$JAVA_OPTS -Xmx${MAX_HEAP_SIZE}"
fi

echo "########################################"
echo "# RUN_JAVA=$RUN_JAVA"
echo "# JAVA_OPTS=$JAVA_OPTS"
echo "# starting now...."
echo "########################################"

java -server $JAVA_OPTS -Dhazelcast.mancenter.home=$MANCENTER_DATA -cp mancenter-$HZ_VERSION.war:$CLASSPATH_ARG/* Launcher 8080 mancenter
