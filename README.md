# Table of Contents

* [Hazelcast Quick Start](#hazelcast-quick-start)
* [Hazelcast Hello World](#hazelcast-hello-world)
* [Hazelcast Enterprise Quick Start](#hazelcast-enterprise-quick-start)
* [Hazelcast Docker Repositories](#hazelcast-docker-repositories)
* [Hazelcast Defined Environment Variables](#setting-environment-variables)
* [Using Custom Hazelcast Configuration File](#using-custom-hazelcast-configuration-file)
* [Extending Hazelcast Base Image](#extending-hazelcast-base-image)
* [Stopping a Hazelcast Member](#stopping-a-hazelcast-member)
* [Management Center](#management-center)
* [Hazelcast Kubernetes](#hazelcast-kubernetes)
* [Hazelcast Openshift](#hazelcast-openshift)
* [Hazelcast Docker Files](#hazelcast-docker-files)


# Hazelcast Quick Start

You can launch Hazelcast Docker Container by running the following command. You can find the full list of Hazelcast versions to replace $HAZELCAST_VERSION at [Official Hazelcast Docker Hub](https://store.docker.com/community/images/hazelcast/hazelcast/tags).

```
docker run -ti hazelcast/hazelcast:$HAZELCAST_VERSION
```
This command will pull Hazelcast Docker image and run server.sh to start a new Hazelcast Instance.

# Hazelcast Hello World

For the simplest end-to-end scenario, you can create a Hazelcast cluster with two Docker containers and access it from the client application.

```
docker run -it -e JAVA_OPTS="-Dhazelcast.local.publicAddress=<host_ip>:5701" -p 5701:5701 hazelcast/hazelcast
docker run -it -e JAVA_OPTS="-Dhazelcast.local.publicAddress=<host_ip>:5702" -p 5702:5701 hazelcast/hazelcast 
```

Note that:
* each container must publish the `5701` port under a different host machine port (`5701` and `5702` in the example)
* `<host_ip>` needs to be the host machine address that will be used for the Hazelcast communication

After setting up the cluster, you can start the [client](https://github.com/hazelcast/hazelcast-code-samples/tree/master/clients/basic) application to check it works correctly.

# Hazelcast Enterprise Quick Start

You can launch Hazelcast Enterprise Docker Container by running the following command. You can find the full list of Hazelcast Enterprise versions to replace $HAZELCAST_VERSION at [Official Hazelcast Docker Hub](https://store.docker.com/community/images/hazelcast/hazelcast-enterprise/tags).

please contact sales@hazelcast.com for trial license.

```
docker run -ti -e HZ_LICENSE_KEY=YOUR_LICENSE_KEY hazelcast/hazelcast-enterprise:$HAZELCAST_VERSION
```

# Hazelcast Docker Repositories

You can find all Hazelcast Docker Images on Docker Store Hazelcast Page.
https://store.docker.com/profiles/hazelcast

N.B. Hazelcast Docker Images (Enterprise Edition and Open Source) are based on Alpine Linux.

# Hazelcast Defined Environment Variables

You can give environment variables to the Hazelcast member within your Docker command. Currently, we support the variables  `MIN_HEAP_SIZE` and `MAX_HEAP_SIZE` inside our start script. An example command is as follows:

```
docker run -e MIN_HEAP_SIZE="1g" -ti hazelcast/hazelcast
```

You can also define your environment variables inside a file as shown in the following example command:

```
docker run --env-file <file-path> -ti hazelcast/hazelcast
```

As shown below, you can use `JAVA_OPTS` environment variable if you need to pass multiple VM arguments to your Hazelcast member.

```
docker run -e JAVA_OPTS="-Xms512M -Xmx1024M" -ti hazelcast/hazelcast
```

# Using Custom Hazelcast Configuration File

If you need to configure with your own `hazelcast.xml` or jar files with your own domain classes, you need to mount the folder that has those files. Also, while running the Docker image, you need to pass the `hazelcast.xml` file path to `hazelcast.config` in `JAVA_OPTS` parameter. Please see the following example:

```
docker run -e JAVA_OPTS="-Dhazelcast.config=/opt/hazelcast/config_ext/hazelcast.xml" -v PATH_TO_LOCAL_CONFIG_FOLDER:/opt/hazelcast/config_ext -ti hazelcast/hazelcast
```

# Extending Hazelcast Base Image

You can use Hazelcast Docker Image to start a new Hazelcast member with default configuration. If you'd like to customize your Hazelcast member, you can extend the Hazelcast base image, provide your own configuration file and customize your initialization process. In order to do that, you need to create a new `Dockerfile` and build it with `docker build` command. 

In the `Dockerfile` example below, we are creating a new image based on the Hazelcast image and adding our own configuration file from our host to the container, which is going to be used with Hazelcast when the container runs.

```
FROM hazelcast/hazelcast:$HAZELCAST_VERSION
# Add your custom hazelcast.xml
ADD hazelcast.xml $HZ_HOME
# Run hazelcast
CMD ./server.sh
```

After creating the `Dockerfile` you need to build it by running the command below:

```
docker build .
```

Now you can run your own container with its ID or tag (if you provided `-t` option while building the image) using the `docker run` command.

## Stopping a Hazelcast Member

You can `stop` the member using the script `stop.sh`. For this purpose, you need to run the following command to the running Docker container:

```
docker exec -it "id of running container" /opt/hazelcast/stop.sh
```

You can check the logs thereafter using the following command:

```
docker logs "id of running container"
```

# Management Center

Please see [Management Center Repository](https://github.com/hazelcast/management-center-docker) for Dockerfile definitions and have a look at available images on [Docker Hub](https://store.docker.com/profiles/hazelcast) page.

# Hazelcast Kubernetes

Hazelcast maintains two Docker Images for Kubernetes Environment. Below are the links to their README files. You can also find Docker Images on [Docker Hub](https://store.docker.com/profiles/hazelcast) page.

* [hazelcast-kubernetes](https://github.com/hazelcast/hazelcast-docker/blob/master/hazelcast-kubernetes/README.md)
* [hazelcast-enterprise-kubernetes](https://github.com/hazelcast/hazelcast-docker/blob/master/hazelcast-enterprise-kubernetes/README.md)

# Hazelcast Openshift

please see [Hazelcast Openshift Repository](https://github.com/hazelcast/hazelcast-openshift) for Dockerfile definitions and have a look available images on [Docker Hub](https://store.docker.com/profiles/hazelcast) page.

# Hazelcast Docker Files

You can find Docker files by going to corresponding `hazelcast-docker` repo tag.
See the full list here: https://github.com/hazelcast/hazelcast-docker/releases
