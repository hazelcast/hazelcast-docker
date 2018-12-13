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

if [ -n "${MIN_HEAP_SIZE}" ]; then
  export JAVA_OPTS="${JAVA_OPTS} -Xms${MIN_HEAP_SIZE}"
fi

if [ -n "${MAX_HEAP_SIZE}" ]; then
  export JAVA_OPTS="${JAVA_OPTS} -Xmx${MAX_HEAP_SIZE}"
fi

if [ -n "${MANCENTER_URL}" ]; then
  export JAVA_OPTS="${JAVA_OPTS} -Dhazelcast.mancenter.enabled=true -Dhazelcast.mancenter.url=${MANCENTER_URL}"
else
  export JAVA_OPTS="${JAVA_OPTS} -Dhazelcast.mancenter.enabled=false"
fi

if [ -n "${HZ_LICENSE_KEY}" ]; then
  export JAVA_OPTS="${JAVA_OPTS} -Dhazelcast.enterprise.license.key=${HZ_LICENSE_KEY}"
else
  set +u 
  export JAVA_OPTS="${JAVA_OPTS} -Dhazelcast.enterprise.license.key=${HZ_LICENCE_KEY}"
  set -u 
fi

echo "########################################"
echo "# JAVA_OPTS=${JAVA_OPTS}"
echo "# CLASSPATH=${CLASSPATH}"
echo "# starting now...."
echo "########################################"
set -x
exec java -server ${JAVA_OPTS} com.hazelcast.core.server.StartServer
