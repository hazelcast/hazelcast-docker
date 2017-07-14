


## Prerequisites

1) Up and Running OpenShift Container Platform (OCP) version 3.4 or 3.5 that you can login as `system:admin`.

  * You may install OpenShift Container Development Kit from [Redhat](https://developers.redhat.com/products/cdk/download/), if you need to test on your local machine. Please note that
downloading and installing will require Redhat subscription. Moreover, please follow the CDK installation
[document](https://access.redhat.com/documentation/en-us/red_hat_container_development_kit/2.4/html/installation_guide/).
After installation of the CDK, you will need to have an up and running OpenShift Container Platform virtual machine.

<br>
2) RHEL 7.3 host with Docker 1.12 installation to build Hazelcast image. Please follow [this solution](https://access.redhat.com/solutions/253273) to register and subscribe.

![](images/NoteSmall.png) ***NOTE***: *You may use host machines that comes with OCP  installations.*

<br>
3) Another important note would be that this document assumes familiarity with `oc` CLI, OCP and Docker.


## Building Hazelcast Enterprise Image

Hazelcast `Dockerfile` can be built only on RHEL 7.2/7.3 hosts with proper subscription.

Run the following Docker command under `hazelcast-openshift-rhel` directory to build the image on RHEL host:

```
docker build . -t <your-image-name>:<version>
```

To verify the image in Docker, please run the following command in shell:

```
docker images
```

You should see `<your-image-name>` as a repository.


## Pushing Image to Private Docker Registry in OCP

In order to push `hazelcast` image to Docker registry in OCP installation, you can use `default` project in OCP, which has already configured Docker registry and router.

If you choose to start from scratch please install the following components under your project:

* Docker Registry with [this installation guide](https://docs.openshift.com/container-platform/3.4/install_config/registry/deploy_registry_existing_clusters.html).
* Router for accessing Docker registry from URL with [this installation guide](https://docs.openshift.com/container-platform/3.3/install_config/router/default_haproxy_router.html).

And [create a route](https://docs.openshift.com/container-platform/3.3/dev_guide/routes.html) for private Docker registry. This route will be referred as `<route-to-registry>` from now on.

Please also note that you need to login to local Docker registry beforehand with the following command:

```
docker login -a <your-ocp-user> -p <your-token> <route-to-registry>
```

You may get `<your-ocp-user>` from `oc whoami` CLI command on OCP VM after connecting it via `vagrant ssh` or `oc login https://<route-to-ocp>:8443`. Moreover, you can get regarding `<your-token>` from `oc whoami -t` command.

Please be aware that, in order to login to registry and execute push command, `<your-ocp-user>` should have the proper rights.

During `login`, you will probably get SSL handshake error. If you do please add your route to Docker insecure registry list or read the OCP documentation regarding [exposing private registry](https://docs.openshift.com/container-platform/3.5/install_config/registry/securing_and_exposing_registry.html).

After the successful login, you may continue with tagging your image with the following sample command:

 ```
docker tag <your-image-name>:<version> <route-to-registry>\<your-namespace>\<your-image-name>:<version>
```

Now, you can push your image to the private registry using the following command:

```
docker push <route-to-registry>\<your-namespace>\<your-image-name>:<version>
```

To verify the image on OCP, you can execute the following command in OCP shell:

```
oc get imagestreams
```

