#!/bin/bash

set -e
set -o pipefail

# Fill the variables before running the script
WORKDIR=$1
PROJECT=$2
OCP_LOGIN_USERNAME=$3
OCP_LOGIN_PASSWORD=$4
OCP_CLUSTER_URL=$5
RED_HAT_USERNAME=unused
HZ_EE_RHEL_REPO_PASSWORD=$6
RED_HAT_EMAIL=unused
HZ_EE_RHEL_REPOSITORY=$7
RELEASE_VERSION=$8
HAZELCAST_CLUSTER_SIZE=$9
HZ_ENTERPRISE_LICENSE=${10}
HZ_MC_VERSION=${11}
LOGIN_COMMAND="oc login ${OCP_CLUSTER_URL} -u=${OCP_LOGIN_USERNAME} -p=${OCP_LOGIN_PASSWORD} --insecure-skip-tls-verify"

# LOG INTO OpenShift
eval "${LOGIN_COMMAND}"

# CREATE PROJECT
oc new-project $PROJECT

oc create secret docker-registry hz-pull-secret \
 --docker-server=scan.connect.redhat.com \
 --docker-username=$RED_HAT_USERNAME \
 --docker-password=$HZ_EE_RHEL_REPO_PASSWORD \
 --docker-email=$RED_HAT_EMAIL

helm repo add hazelcast https://hazelcast-charts.s3.amazonaws.com/
helm repo update

sed -i "s|HZ_EE_RHEL_REPOSITORY|\"${HZ_EE_RHEL_REPOSITORY}\"|g" ${WORKDIR}/values.yaml
sed -i "s/RELEASE_VERSION/\"${RELEASE_VERSION}\"/g" ${WORKDIR}/values.yaml
sed -i "s/PULL_SECRET/hz-pull-secret/g" ${WORKDIR}/values.yaml
sed -i "s/HAZELCAST_CLUSTER_SIZE/${HAZELCAST_CLUSTER_SIZE}/g" ${WORKDIR}/values.yaml
sed -i "s/HZ_ENTERPRISE_LICENSE/${HZ_ENTERPRISE_LICENSE}/g" ${WORKDIR}/values.yaml
sed -i "s/HZ_MC_VERSION/\"${HZ_MC_VERSION}\"/g" ${WORKDIR}/values.yaml
sed -i "s/MC_MAJOR_VERSION/${HZ_MC_VERSION:0:1}/g" ${WORKDIR}/values.yaml

helm install ${PROJECT} -f ${WORKDIR}/values.yaml hazelcast/hazelcast-enterprise 
