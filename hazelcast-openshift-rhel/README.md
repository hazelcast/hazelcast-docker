% HAZELCAST(1) RHEL7 Container Image Pages
% Hazelcast, Inc.
% March 16, 2017


# DESCRIPTION

This image simplifies the deployment of a Hazelcast Enterprise based standalone infrastructure. As a certified
Red Hat Enterprise Linux based image. It is built on top of RHEL 7.

This package consists of the following parts:

* Hazelcast Enterprise and regarding dependencies
* Red Hat Enterprise Linux (RHEL) 7
* Oracle Java 8
* Health and liveness scripts
* Start and stop scripts

# USAGE

## Build and Deployment to Private Docker Registry

### Prerequisites

1) Install Docker Engine on your development/test machine from [Docker Installations](https://docs.docker.com/engine/installation/)

2) Up and Running Openshift Container Platform (OCP) on your premise.
* Install Openshift Container Development Kit from [Redhat](https://developers.redhat.com/products/cdk/download/), if you need to test on your local machine. Please note that
downloading and installation will require Redhat subscription. Moreover, please follow CDK installation
[document](https://access.redhat.com/documentation/en-us/red_hat_container_development_kit/2.4/html/installation_guide/)

* After installation of CDK, you will need to have up and running Openshift Container Platform virtual machine.

Another important note would be that this document assumes familiarity with `oc` CLI and OCP  knowledge. Therefore, if you need further information please refer to Redhat OCP documentation.

### Building Hazelcast Enterprise Image

In order to build docker image you will also need Redhat subscription. Please refer to Redhat documentation for subscription and activation for your account.

Run below ```docker``` command under ```hazelcast-openshift-rhel``` directory to build image with your Redhat subscription credentials.

```
docker build --build-arg user=<your-user-name> --build-arg password=<your-password> . -t <your-image-name>:<version>
```

To verify image in Docker please run below command in shell:
```
docker images
```
You should see `<your-image-name>` as a repository.

### Pushing Image to Private Docker Registry in OCP

In order to push ```hazelcast``` image to docker registry in local OCP installation, you may use ```default``` project in OCP, which has already configured docker registry.

Please also note that you need to login local docker registry before hand.
Moreover, you may refer to [this document](https://docs.openshift.com/enterprise/3.2/install_config/install/docker_registry.html) for docker registry installation in OCP.

 ```
 docker login -a <your-ocp-user> -p <your-token> <route-to-registry>
 ```

You may get `<your-ocp-user>` from `oc whoami` CLI command on OCP VM, after connecting it via `vagrant ssh` or `oc login https://<route-to-ocp>:8443`. Moreover, you can get regarding `<your-token>` from `oc whoami -t` command.

Please beware that, in order to login registry, and execute push command `<your-ocp-user>` should have proper rights.

 During ```login``` you will probably get SSL handshake error, if you do please add your route to docker insecure registry list.

After successful, login you may continue with ```taging``` your image with below sample command.
 ```
 docker tag <your-image-name>:<version> <route-to-registry>\<your-namespace>\<your-image-name>:<version>
  ```
Now, you can push your image to private registry with below command.

```
docker push <route-to-registry>\<your-namespace>\<your-image-name>:<version>
```

To verify image on OCP, you may execute below command in OCP shell.
```
oc get imagestreams
```

## Starting Hazelcast Enterprise Cluster

* Before starting to deploy Hazelcast Enterprise cluster make sure that you have a valid License key for Hazelcast Enterprise version.
  * You may get a trial key from [this link](https://hazelcast.com/hazelcast-enterprise-download/trial/)

### Deploying on Web Console

* In web browser, navigate to your OCP console page and login.
  * Your login user should have required access right to start docker registry and push images as described in `Build and Deployment to Private Docker Registry` section of this document.

* Create a project with `your-project-name`.
  ![create](markdown/images/create-new-project.png)

* Turn back to OCP shell and switch to your new project with `oc project <your-project-name>` command

* Add private Docker registry to your project
  * Please refer to [this link](https://docs.openshift.com/enterprise/3.2/install_config/install/docker_registry.html) for details.
  * Or you may create a infrastructure project to deploy your project `imagestreams`.

  ![registry](markdown/images/registry.png)

* Add route for newly created docker registry, please assign `passthrough` for TLS setting
  ![registry-route](markdown/images/route-registry.png)

* Push your Hazelcast Enterprise image to this registry, as described in section `Pushing Image to Private Docker Registry in OCP`.

* To verify pushed image in OCP, you may run below command
```
oc get imagestreams
```
You should see `<your-image-name>` under `NAME` column as below. In my case, it is named as `hz-enterprise`.
![image-stream](markdown/images/image-stream.png)

Another important point would be the `DOCKER REPO` entry for image, in succeeding part we will use this path in `kubernetes-template.js` to pull base image for our Hazelcast cluster.

* Click `Add to Project` and then `Import YAML/JSON` to start deploying Hazelcast cluster on OCP.

* Copy and Paste the contents of `kubernetes-template.js` on to editor, or browse and upload it.
  * This template file contains all the deployment information to setup a Hazelcast cluster from inside Openshift.
  It configures the necessary ReplicationController, healthchecks and image to use. It also offers a set of properties to be requested when creating a new cluster (such as clustername).

* Change `"image": "hazelcast/openshift"` to `"image":"<registry-route>/<your-namespace>/<your-image-name>"`

* Fill out Configuration properties section
  * `NAMESPACE` value is important and should match with your project namespace.

* ...and it is ready to go.

    ![over](markdown/images/over.png)


# LABELS

Following labels are set for this image:

`name=`

The registry location and name of the image.

`version=`

The Red Hat Enterprise Linux version from which the container was built.

`release=`

The Hazelcast release version built into this image.


# SECURITY IMPLICATIONS

This image exposes port 5701 as the external port for cluster communication (member to member)
and between Hazelcast clients and the Hazelcast cluster (client-server).

The port is reachable from inside the Openshift environment only and is not registered for public
reachability.


# HISTORY

Initial version


# AUTHORS

Hazelcast, Inc.
