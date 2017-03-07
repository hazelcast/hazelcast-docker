{
	"apiVersion": "v1",
	"kind": "Template",
	"metadata": {
		"name": "hazelcast-openshift-rhel",
		"annotations": {
			"description": "Openshift deployment template for Hazelcast based on RHEL 7",
			"tags": "hazelcast, imdg, datagrid, inmemory, kvstore, nosql, java",
			"iconClass": "icon-java"
		}
	},

	"labels": {
		"template": "hazelcast-openshift-rhel-template"
	},

	"objects": [{
		"apiVersion": "v1",
		"kind": "ReplicationController",
		"metadata": {
			"generateName": "hazelcast-cluster-rc-${DEPLOYMENT_NAME}-"
		},
		"spec": {
			"replicas": 3,
			"selector": {
				"name": "hazelcast-node-${DEPLOYMENT_NAME}"
			},
			"template": {
				"metadata": {
					"name": "hazelcast-node",
					"generateName": "hazelcast-node-${DEPLOYMENT_NAME}-",
					"labels": {
						"name": "hazelcast-node-${DEPLOYMENT_NAME}"
					}
				},
				"spec": {
					"containers": [{
						"image": "hazelcast/openshift",
						"name": "hazelcast-openshift-rhel",
						"env": [{
							"name": "HAZELCAST_KUBERNETES_SERVICE_DNS",
							"value": "${SERVICE_NAME}.${NAMESPACE}.svc.${KUBERNETES_SERVICE_DOMAIN}"
						}, {
							"name": "HAZELCAST_KUBERNETES_SERVICE_NAME",
							"value": "${SERVICE_NAME}"
						}, {
							"name": "HAZELCAST_KUBERNETES_NAMESPACE",
							"value": "${NAMESPACE}"
						}, {
							"name": "HAZELCAST_KUBERNETES_SERVICE_DNS_IP_TYPE",
							"value": "IPV4"
						}, {
							"name": "HAZELCAST_KUBERNETES_SERVICE_DOMAIN",
							"value": "${KUBERNETES_SERVICE_DOMAIN}"
						}],
						"ports": [{
							"containerPort": 5701,
							"protocol": "TCP"
						}],
						"readinessProbe": {
							"exec": {
								"command": ["./healthcheck.sh"]
							},
							"initialDelaySeconds": 1,
							"timeoutSeconds": 5
						},
						"livenessProbe": {
							"exec": {
								"command": ["./healthcheck.sh"]
							},
							"initialDelaySeconds": 60,
							"timeoutSeconds": 5
						}
					}]
				}
			},
			"triggers": {
				"type": "ImageChange"
			}
		}
	}, {
		"apiVersion": "v1",
		"kind": "Service",
		"metadata": {
			"name": "${SERVICE_NAME}"
		},
		"spec": {
			"type": "ClusterIP",
			"clusterIP": "None",
			"selector": {
				"name": "hazelcast-node-${DEPLOYMENT_NAME}"
			},
			"ports": [{
				"port": 5701,
				"protocol": "TCP"
			}]
		}
	}],

	"parameters": [{
		"name": "DEPLOYMENT_NAME",
		"description": "Defines the base name of this deployment unit",
		"required": true
	}, {
		"name": "SERVICE_NAME",
		"description": "Defines the service name of the POD to lookup of Kubernetes.",
		"required": true
	}, {
		"name": "NAMESPACE",
		"description": "Defines the namespace of the application POD of Kubernetes, if not defined the container will use the value of /var/run/secrets/kubernetes.io/serviceaccount/namespace",
		"required": false
	}, {
		"name": "KUBERNETES_SERVICE_DOMAIN",
		"description": "Defines the domain part of a kubernetes dns lookup.",
		"value": "cluster.local",
		"required": true
	}]
}
