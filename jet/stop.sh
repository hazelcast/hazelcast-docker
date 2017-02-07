#!/bin/sh

PRG="$0"
PRGDIR=`dirname "$PRG"`
JET_HOME=`cd "$PRGDIR/.." >/dev/null; pwd`/hazelcast-jet
PID_FILE=$JET_HOME/jet_instance.pid
PID=$(cat ${PID_FILE});

if [ -z "${PID}" ]; then
    echo "${PID_FILE}.pid is not running (missing PID)."
else
   kill ${PID}
fi
