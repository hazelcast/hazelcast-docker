#!/bin/bash
PID=0
sigterm_handler() {
  echo "Jet Term Handler received shutdown signal. Signaling jet instance on PID: ${PID}"
  if [ ${PID} -ne 0 ]; then
    kill "${PID}"
  fi
}

PRG="$0"
PRGDIR=`dirname "$PRG"`
JET_HOME=`cd "$PRGDIR/.." >/dev/null; pwd`/hazelcast-jet
PID_FILE=$JET_HOME/jet_instance.pid

if [ "x$MIN_HEAP_SIZE" != "x" ]; then
	JAVA_OPTS="$JAVA_OPTS -Xms${MIN_HEAP_SIZE}"
fi

if [ "x$MAX_HEAP_SIZE" != "x" ]; then
	JAVA_OPTS="$JAVA_OPTS -Xmx${MAX_HEAP_SIZE}"
fi

# if we receive SIGTERM (from docker stop) or SIGINT (ctrl+c if not running as daemon)
# trap the signal and delegate to sigterm_handler function, which will notify jet instance process
trap sigterm_handler SIGTERM SIGINT

export CLASSPATH=$JET_HOME/hazelcast-jet-$JET_VERSION.jar:$CLASSPATH/*

echo "########################################"
echo "# RUN_JAVA=$RUN_JAVA"
echo "# JAVA_OPTS=$JAVA_OPTS"
echo "# starting now...."
echo "########################################"

java -server $JAVA_OPTS com.hazelcast.jet.server.StartServer &
PID="$!"
echo "Process id ${PID} for jet instance is written to location: " $PID_FILE
echo ${PID} > ${PID_FILE}

# wait on jet instance process
wait ${PID}
# if a signal came up, remove previous traps on signals and wait again (noop if process stopped already)
trap - SIGTERM SIGINT
wait ${PID}
