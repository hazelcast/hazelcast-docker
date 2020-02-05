#!/bin/bash

set -euo pipefail

eval JAVA_OPTS=\"${JAVA_OPTS}\"
eval CLASSPATH=\"${CLASSPATH}\"

if [ -n "${CLASSPATH}" ]; then 
  export CLASSPATH="${CLASSPATH_DEFAULT}:${CLASSPATH}"
else
  export CLASSPATH="${CLASSPATH_DEFAULT}"
fi

if [ -n "${JAVA_OPTS}" ]; then
  export JAVA_OPTS="${JAVA_OPTS_DEFAULT} ${JAVA_OPTS}"
else
  export JAVA_OPTS="${JAVA_OPTS_DEFAULT}"
fi

if [ -n "${PROMETHEUS_PORT}" ]; then
  export JAVA_OPTS="-javaagent:${HZ_HOME}/lib/jmx_prometheus_javaagent.jar=${PROMETHEUS_PORT}:${PROMETHEUS_CONFIG} ${JAVA_OPTS}"
fi

if [ -n "${LOGGING_LEVEL}" ]; then
  sed -i "s/java.util.logging.ConsoleHandler.level = INFO/java.util.logging.ConsoleHandler.level = ${LOGGING_LEVEL}/g" logging.properties
  sed -i "s/.level= INFO/.level= ${LOGGING_LEVEL}/g" logging.properties
fi

if [ -n "${HZ_LICENSE_KEY}" ]; then
  export JAVA_OPTS="${JAVA_OPTS} -Dhazelcast.enterprise.license.key=${HZ_LICENSE_KEY}"
else
  set +u 
  export JAVA_OPTS="${JAVA_OPTS} -Dhazelcast.enterprise.license.key=${HZ_LICENCE_KEY}"
  set -u 
fi

export JAVA_OPTS="${JAVA_OPTS} -Dhazelcast.tls.enabled=${TLS_ENABLED:-false}"

echo "########################################"
echo "# JAVA_OPTS=${JAVA_OPTS}"
echo "# CLASSPATH=${CLASSPATH}"
echo "# starting now...."
echo "########################################"
set -x
exec java -server ${JAVA_OPTS} com.hazelcast.core.server.HazelcastMemberStarter
