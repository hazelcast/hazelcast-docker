This repository includes a default configuration file, sample YAML configuration files and 
the Dockerfile to deploy a Hazelcast Enterprise based standalone infrastructure as a Centos 7 based image
in Kubernetes.

- [Introduction](#introduction)
- [Deploying](#deploying)
- [Labels](#labels)
- [Security Implications](#security-implications)


# Introduction

This image simplifies the deployment in Kubernetes of a Hazelcast Enterprise based standalone infrastructure, as a
Centos 7 based image.

This package consists of the following parts:

* Hazelcast Enterprise and related dependencies, including the [`hazelcast-kubernetes`](https://github.com/hazelcast/hazelcast-kubernetes) discovery plugin
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

## Starting Hazelcast Enterprise Cluster

The sample YAML files are sufficient for the basic use case. See below if you need to use custom configurations.

In order to run with the default configuration, just take the following steps.

Create a secret for your license key:

    $ kubectl create secret generic hz-ee-license --from-literal=key=LICENSE-KEY-HERE

Edit the Service and the ReplicationController in the sample `hazelcast-ee-service.yaml` config file to suit your needs.
  - You may specify a custom service name or cluster size.
  - You may change the image name, e.g., to refer to a custom image or to a specific Hazelcast Enterprise version.

Edit the ConfigMap in the sample `hz-ee-config.yaml` and specify the service name and the Kubernetes namespace
(the default namespace is "default").

Install the Hazelcast Enterprise ConfigMap:

    $ kubectl apply -f hz-ee-config.yaml

Finally, deploy the Hazelcast Enterprise cluster:

    $ kubectl apply -f hazelcast-ee-service.yaml


### Custom Configurations

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

Now edit `hazelcast-ee-service.yaml` and a PersistentVolumeClaim definition to match the above PersistenVolume.
Finally, set the `HZ_DATA` env variable to a valid path and add a corresponding `volumeMount` in the
ReplicationController.

This is what it should look like:

```yaml
apiVersion: v1
kind: Service
metadata:
  name: hazelcast-ee
  labels:
    app: hazelcast-ee
spec:
  type: NodePort
  selector:
    app: hazelcast-ee
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
  name: hazelcast-ee
spec:
  replicas: 3
  template:
    metadata:
      labels:
        app: hazelcast-ee
    spec:
      containers:
      - name: hazelcast-ee-node
        image: hazelcast/hazelcast-enterprise-kubernetes:3.9
        ports:
        - containerPort: 5701
        livenessProbe:
          exec:
            command:
            - "./liveness.sh"
          initialDelaySeconds: 30
          timeoutSeconds: 5
          periodSeconds: 10
        envFrom:
        - configMapRef:
            name: hz-ee-config
        env:
        - name: HZ_LICENSE_KEY
          valueFrom:
            secretKeyRef:
              name: hz-ee-license
              key: key
        - name: HZ_DATA
          value: /data/hazelcast
        volumeMounts:
          - name: hz-persistent-storage
            mountPath: /data/hazelcast
      volumes:
        - name: hz-persistent-storage
          persistentVolumeClaim:
            claimName: hz-vc
```

# Security Implications

This image exposes port 5701 as the external port for cluster communication (member to member) and between 
Hazelcast clients and cluster (client-server).

The port is reachable from the Kubernetes environment only and is not registered to be publicly reachable.
