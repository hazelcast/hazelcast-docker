#!/bin/bash

set -e
set -o pipefail

# Fill the variables before running the script
WORKDIR=$1
PROJECT=$2
OCP_LOGIN_USERNAME=$3
OCP_LOGIN_PASSWORD=$4
OCP_CLUSTER_URL=$5
SCAN_REGISTRY_USER=$6
SCAN_REGISTRY_PASSWORD=$7
SCAN_REPOSITORY=$8
RELEASE_VERSION=$9
HAZELCAST_CLUSTER_SIZE=${10}
HZ_ENTERPRISE_LICENSE=${11}
HZ_MC_VERSION=${12}
SCAN_REGISTRY=${13}
LOGIN_COMMAND="oc login ${OCP_CLUSTER_URL} -u=${OCP_LOGIN_USERNAME} -p=${OCP_LOGIN_PASSWORD} --insecure-skip-tls-verify"

# LOG INTO OpenShift
eval "${LOGIN_COMMAND}"

# CREATE PROJECT
oc new-project $PROJECT

oc create secret docker-registry hz-pull-secret \
 --docker-server=$SCAN_REGISTRY \
 --docker-username=$SCAN_REGISTRY_USER \
 --docker-password=$SCAN_REGISTRY_PASSWORD \
 --docker-email=unused

helm repo add hazelcast https://hazelcast-charts.s3.amazonaws.com/
helm repo update

sed -i "s|SCAN_REPOSITORY|\"${SCAN_REPOSITORY}\"|g" ${WORKDIR}/values.yaml
sed -i "s/RELEASE_VERSION/\"${RELEASE_VERSION}\"/g" ${WORKDIR}/values.yaml
sed -i "s/PULL_SECRET/hz-pull-secret/g" ${WORKDIR}/values.yaml
sed -i "s/HAZELCAST_CLUSTER_SIZE/${HAZELCAST_CLUSTER_SIZE}/g" ${WORKDIR}/values.yaml
sed -i "s/HZ_ENTERPRISE_LICENSE/${HZ_ENTERPRISE_LICENSE}/g" ${WORKDIR}/values.yaml
sed -i "s/HZ_MC_VERSION/\"${HZ_MC_VERSION}\"/g" ${WORKDIR}/values.yaml
sed -i "s/MC_MAJOR_VERSION/${HZ_MC_VERSION:0:1}/g" ${WORKDIR}/values.yaml

helm install ${PROJECT} -f ${WORKDIR}/values.yaml hazelcast/hazelcast-enterprise 
