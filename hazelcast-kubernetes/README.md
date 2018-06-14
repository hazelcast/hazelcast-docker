This repository includes a default configuration file, sample YAML configuration files and 
the Dockerfile to deploy a Hazelcast based standalone infrastructure as a Centos 7 based image
in Kubernetes.

- [Introduction](#introduction)
- [Deploying](#deploying)
  - [Prerequisites](#prerequisites)
  - [Starting Hazelcast Cluster](#starting-hazelcast-cluster)
  - [Custom Configuration](#custom-configuration)
    - [Persistent Volume](#persistent-volume)
    - [Config Map](#config-map)
- [Security Implications](#security-implications)


# Introduction

This image simplifies the deployment in Kubernetes of a Hazelcast based standalone infrastructure, as a
Centos 7 based image.

This package consists of the following parts:

* Hazelcast and related dependencies, including the [`hazelcast-kubernetes`](https://github.com/hazelcast/hazelcast-kubernetes) discovery plugin
* Centos 7
* OpenJDK 8
* Health and liveness scripts
* Start and stop scripts

# Deploying

## Prerequisites

1) Up and running [Kubernetes](https://kubernetes.io) version 1.6 or higher.

  * For development and testing, you may use [Minikube](https://kubernetes.io/docs/getting-started-guides/minikube/)
  * You must have the Kubernetes command line tool, [kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl/),
    installed

2) Another important note would be that this document assumes some familiarity with `kubectl`, Kubernetes, and Docker.

## Starting Hazelcast Cluster

The sample YAML files are sufficient for the basic use case. See below if you need to use custom configurations.

In order to run with the default configuration, just take the following steps.

Edit the Service and the ReplicationController 
in the sample `hazelcast-service.yaml` config file to suit your needs.
  - You may specify a custom service name or cluster size.
  - You may change the image name, e.g., to refer to a custom image or to a specific Hazelcast version.

Edit the ConfigMap in the sample `hz-config.yaml` and specify the service name and the Kubernetes namespace
(the default namespace is "default").

Install the Hazelcast ConfigMap:

    $ kubectl apply -f hz-config.yaml

Finally, deploy the Hazelcast cluster:

    $ kubectl apply -f hazelcast-service.yaml


## Custom Configuration

There are two ways to use custom Hazelcast configuration: Persistent Volume or Config Map. Only the first one works if you want to use custom domain JARs.

### Persistent Volume

This is a **prerequisite** step if you have custom configurations or JARs.

In order to share custom configurations or custom domain JARs (for example `EntryProcessor` implementations)
among Hazelcast pods, you need to add a persistent volume in Kubernetes.

The `start.sh` script in this Docker images will use an environment variable named `HZ_DATA`, if defined,
as the location for additional JARs and a custom `hazelcast.xml`.

There are many different ways you can define and map volumes in Kubernetes.
Types of volumes are discussed in the [official documentation](https://kubernetes.io/docs/concepts/storage/volumes/).

Once you have created a volume, copy your custom Hazelcast configuration there as `hazelcast.xml`. 
You may also copy or transfer custom JARs to the volume root directory.

In the following example a GCE Persistent Disk named "my-hz-disk" has been already created and populated with the
custom configuration.

* Open a text editor and add the following deployment YAML for persistent volume:

```yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: hz-pv
spec:
  capacity:
    storage: 10Gi
  storageClassName: standard
  accessModes:
    - ReadWriteOnce
    - ReadOnlyMany
  persistentVolumeReclaimPolicy: Retain
  gcePersistentDisk:
    pdName: my-hz-disk
    fsType: ext4
```

Save this file as `hz-pv.yaml`. Please also notice that `Reclaim Policy` is set as `Retain`. 
Therefore, contents of this folder will remain as is, between successive `claims`.

Create the persistent volume:

    $ kubectl apply -f hz-pv.yaml

Please note that contents of your previous deployment is preserved. 
If you change the claim policy to `RECYCLE`, you have to transfer all custom files to `<your-pv-path>` 
before each successive deployments.

Now edit `hazelcast-service.yaml` and a PersistentVolumeClaim definition to match the above PersistenVolume.
Finally, set the `HZ_DATA` env variable to a valid path and add a corresponding `volumeMount` in the
ReplicationController.

This is what it should look like:

```yaml
apiVersion: v1
kind: Service
metadata:
  name: hazelcast
  labels:
    app: hazelcast
spec:
  type: NodePort
  selector:
    app: hazelcast
  ports:
  - protocol: TCP
    port: 5701
    name: hzport
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: hz-vc
spec:
  storageClassName: standard
  accessModes:
    - ReadOnlyMany
  resources:
    requests:
      storage: 10Gi
  volumeName: hz-pv
---
apiVersion: v1
kind: ReplicationController
metadata:
  name: hazelcast
spec:
  replicas: 3
  template:
    metadata:
      labels:
        app: hazelcast
    spec:
      containers:
      - name: hazelcast-node
        image: hazelcast/hazelcast-kubernetes:3.10.2
        ports:
        - containerPort: 5701
        livenessProbe:
          httpGet:
            path: /hazelcast/health/node-state
            port: 5701
          initialDelaySeconds: 30
          timeoutSeconds: 5
          periodSeconds: 10
        envFrom:
        - configMapRef:
            name: hz-config
        env:
        - name: HZ_DATA
          value: /data/hazelcast
        volumeMounts:
          - name: hazelcast-storage
            mountPath: /data/hazelcast
      volumes:
        - name: hazelcast-storage
          persistentVolumeClaim:
            claimName: hz-vc
```

### Config Map

The Hazelcast configuration can be stored as ConfigMap and used by the Hazelcast node.

In order to do it, copy `hazelcast.xml` into the `hazelcast-configuration` directory. Then, create a `ConfigMap`.

    $ kubectl create configmap hazelcast-configuration --from-file hazelcast-configuration

Finally, mount ConfigMap into `/data/hazelcast` the same way it was done in case of Persistent Volume. The `hazelcast-service.yaml` file can look as follows:

```yaml
apiVersion: v1
kind: Service
metadata:
  name: hazelcast
  labels:
    app: hazelcast
spec:
  type: NodePort
  selector:
    app: hazelcast
  ports:
  - protocol: TCP
    port: 5701
    name: hzport
---
apiVersion: v1
kind: ReplicationController
metadata:
  name: hazelcast
spec:
  replicas: 3
  template:
    metadata:
      labels:
        app: hazelcast
    spec:
      containers:
      - name: hazelcast-node
        image: hazelcast/hazelcast-kubernetes:3.10.2
        ports:
        - containerPort: 5701
        livenessProbe:
          httpGet:
            path: /hazelcast/health/node-state
            port: 5701
          initialDelaySeconds: 30
          timeoutSeconds: 5
          periodSeconds: 10
        envFrom:
        - configMapRef:
            name: hz-config
        env:
        - name: HZ_DATA
          value: /data/hazelcast
        volumeMounts:
          - name: hazelcast-storage
            mountPath: /data/hazelcast
      volumes:
        - name: hazelcast-storage
          configMap:
            name: hazelcast-configuration
```

# Security Implications

This image exposes port 5701 as the external port for cluster communication (member to member) and between 
Hazelcast clients and cluster (client-server).

The port is reachable from the Kubernetes environment only and is not registered to be publicly reachable.

# Troubleshooting

If after the deployment you see the pods failing all the time:

    $ kubectl get pods --selector app=hazelcast

```
NAME              READY     STATUS             RESTARTS   AGE
hazelcast-46ndm   0/1       Error              4          3m
hazelcast-547j4   0/1       Error              4          3m
hazelcast-7m5dn   0/1       CrashLoopBackOff   4          3m
```

and in the logs 

    $ kubectl logs POD

you can see a line like this one:

`SEVERE: [172.17.0.8]:5701 [dev] [3.10.1] Failure executing: GET at: https://kubernetes.default.svc/api/v1/namespaces/default/endpoints/hazelcast. Message: Forbidden!Configured service account doesn't have access. Service account may have been revoked. endpoints "hazelcast" is forbidden: User "system:serviceaccount:default:default" cannot get endpoints in the namespace "default".
`

Then you have to grant authorization, so the pods can connect Kubernetes' API. Create a new file _hazelcast-rbac.yaml_ with this content:

```
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: default-cluster
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: view
subjects:
- kind: ServiceAccount
  name: default
  namespace: default
```

and then apply the changes:

    $ kubectl apply -f hazelcast-rbac.yaml

after a few seconds you'll see the pods up and running and you'll able to use your new Hazelcast cluster.

