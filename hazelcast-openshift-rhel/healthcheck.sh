#!/bin/bash                                                                     
result=$( curl http://127.0.0.1:5701/hazelcast/healthcheck | awk 'match($0, /Hazelcast\:\:ClusterSafe\=([A-Z]*)/)' )                                            
if [ "$result" == "Hazelcast::ClusterSafe=TRUE" ]; then exit 0; else exit 1; fi 
