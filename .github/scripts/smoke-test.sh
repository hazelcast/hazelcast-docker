#!/bin/bash

set -e -o pipefail ${RUNNER_DEBUG:+-x}

# Fill the variables before running the script
WORKDIR=${1}
PROJECT=${2}
SCAN_REGISTRY_USER=${3}
SCAN_REGISTRY_PASSWORD=${4}
SCAN_REPOSITORY=${5}
RELEASE_VERSION=${6}
HAZELCAST_CLUSTER_SIZE=${7}
HZ_ENTERPRISE_LICENSE=${8}
HZ_MC_VERSION=${9}
SCAN_REGISTRY=${10}

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
