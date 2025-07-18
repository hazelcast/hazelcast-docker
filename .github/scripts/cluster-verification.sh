#!/bin/bash

set -o errexit -o nounset -o pipefail ${RUNNER_DEBUG:+-x}

# shellcheck source=../.github/scripts/logging.functions.sh
. .github/scripts/logging.functions.sh

#CHECK IF THE LAST MEMBER POD IS READY
function wait_for_last_member_initialization() {
    local SIZE=$1
    local LAST_MEMBER=$(( $SIZE - 1 ))
    for i in `seq 1 10`; do
        if [[ $(kubectl get pods "${PROJECT_NAME}-${NAME}-${LAST_MEMBER}" -o 'jsonpath={..status.conditions[?(@.type=="Ready")].status}') != "True" ]]; then
            kubectl get pods
            echo "waiting for pod ${PROJECT_NAME}-${NAME}-${LAST_MEMBER} to be ready..." && sleep 30
            if [ "$i" = "10" ]; then
                echoerr "${PROJECT_NAME}-${NAME}-${LAST_MEMBER} pod failed to be ready!"
                kubectl get pods
                echo ""
                kubectl logs "${PROJECT_NAME}-${NAME}-${LAST_MEMBER}"
                return 1
            fi
        else
            echo "${PROJECT_NAME}-${NAME}-${LAST_MEMBER} is ready!"
            return 0
        fi
    done
}

#CHECK IF CLUSTER SIZE IS CORRECT
function verify_cluster_size() {
    local SIZE=$1
    local LAST_MEMBER=$(( $SIZE - 1 ))
    for i in `seq 1 5`; do
        num=$(kubectl logs "${PROJECT_NAME}-${NAME}-${LAST_MEMBER}" | grep "Members {size:${SIZE}, ver:${SIZE}}" | wc -l)
        if [ "$num" = "1" ]; then
            echo "Hazelcast cluster size is ${SIZE}!"
            return 0
        else
            echo "Waiting for cluster size to be ${SIZE}..." && sleep 4
            if [ "$i" = "5" ]; then
                echoerr "Hazelcast cluster size is not ${SIZE}!"
                kubectl get pods
                echo ""
                kubectl logs "${PROJECT_NAME}-${NAME}-${LAST_MEMBER}"
                return 1
            fi
        fi
    done
}


#CHECK IF ALL MEMBERS CAN COMMUNICATE WITH MANAGEMENT CENTER
function verify_management_center() {
    local SIZE=$1
    echo "Verifying Management Center"
    for i in `seq 1 5`; do
        local MEMBER_COUNT=$(kubectl logs "${PROJECT_NAME}-${NAME}-mancenter-0" | grep -E "Started communication with (a new )?member" | wc -l)
        if [ "$MEMBER_COUNT" = "${SIZE}" ]; then
            echo "Management Center monitoring ${SIZE} members!"
            return 0
        else
            echo "Waiting for Management Center to find all ${SIZE} members..." && sleep 4
            if [ "$i" = "5" ]; then
                echoerr "Management Center could not find all ${SIZE} members!"
                kubectl get pods
                echo ""
                kubectl logs "${PROJECT_NAME}-${NAME}-mancenter-0"
                return 1 
            fi
        fi  
    done
}