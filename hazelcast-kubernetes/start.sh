#!/bin/sh

PRG="$0"
PRGDIR=`dirname "$PRG"`
HAZELCAST_HOME=`cd "$PRGDIR/.." >/dev/null; pwd`/hazelcast
HAZELCAST_CP_MOUNT=$HAZELCAST_HOME/external

if [ "x$MIN_HEAP_SIZE" != "x" ]; then
	JAVA_OPTS="$JAVA_OPTS -Xms${MIN_HEAP_SIZE}"
fi

if [ "x$MAX_HEAP_SIZE" != "x" ]; then
	JAVA_OPTS="$JAVA_OPTS -Xmx${MAX_HEAP_SIZE}"
fi

if [ "$HAZELCAST_KUBERNETES_NAMESPACE" == "" ]; then
	HAZELCAST_KUBERNETES_NAMESPACE=$( cat /var/run/secrets/kubernetes.io/serviceaccount/namespace )
fi
echo "Kubernetes Namespace: $HAZELCAST_KUBERNETES_NAMESPACE"

if [ "$HAZELCAST_KUBERNETES_SERVICE_DNS" == "$HAZELCAST_KUBERNETES_SERVICE_NAME..svc.$HAZELCAST_KUBERNETES_SERVICE_DOMAIN" ]; then
	HAZELCAST_KUBERNETES_SERVICE_DNS="$HAZELCAST_KUBERNETES_SERVICE_NAME.$HAZELCAST_KUBERNETES_NAMESPACE.svc.$HAZELCAST_KUBERNETES_SERVICE_DOMAIN"
fi
echo "Kubernetes Service DNS: $HAZELCAST_KUBERNETES_SERVICE_DNS"

export CLASSPATH=$HZ_DATA/*:$HAZELCAST_HOME/*:$HAZELCAST_CP_MOUNT/*:$CLASSPATH

echo "########################################"
echo "# RUN_JAVA=$RUN_JAVA"
echo "# JAVA_OPTS=$JAVA_OPTS"
echo "# CLASSPATH=$CLASSPATH"
echo "########################################"

echo "Checking custom configuration"
FILE=$HZ_DATA/hazelcast.xml
if [[ -r "$FILE" ]];
then
	echo "custom configuration found: $FILE"
	java -server $JAVA_OPTS -Dhazelcast.config=$FILE -Dhazelcast.http.healthcheck.enabled=true -Djava.net.preferIPv4Stack=true com.hazelcast.core.server.StartServer
else
	echo "no custom configuration found"
	java -server $JAVA_OPTS -Dhazelcast.http.healthcheck.enabled=true -Djava.net.preferIPv4Stack=true com.hazelcast.core.server.StartServer
fi
