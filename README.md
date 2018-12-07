# Hazelcast Docker

This repository contains Dockerfiles for the official Hazelcast Docker images.

## Quick Start

### Hazelcast

You can launch Hazelcast Docker Container by running the following command. You can find the full list of Hazelcast versions to replace $HAZELCAST_VERSION at [Official Hazelcast Docker Hub](https://store.docker.com/community/images/hazelcast/hazelcast/tags).

```
$ docker run hazelcast/hazelcast:$HAZELCAST_VERSION
```
This command will pull Hazelcast Docker image and run a new Hazelcast Instance.

### Hazelcast Hello World

For the simplest end-to-end scenario, you can create a Hazelcast cluster with two Docker containers and access it from the client application.

```
$ docker run -e JAVA_OPTS="-Dhazelcast.local.publicAddress=<host_ip>:5701" -p 5701:5701 hazelcast/hazelcast
$ docker run -e JAVA_OPTS="-Dhazelcast.local.publicAddress=<host_ip>:5702" -p 5702:5701 hazelcast/hazelcast 
```

Note that:
* each container must publish the `5701` port under a different host machine port (`5701` and `5702` in the example)
* `<host_ip>` needs to be the host machine address that will be used for the Hazelcast communication

After setting up the cluster, you can start the [client](https://github.com/hazelcast/hazelcast-code-samples/tree/master/clients/basic) application to check it works correctly.

### Hazelcast Enterprise

You can launch Hazelcast Enterprise Docker Container by running the following command. You can find the full list of Hazelcast Enterprise versions to replace $HAZELCAST_VERSION at [Official Hazelcast Docker Hub](https://store.docker.com/community/images/hazelcast/hazelcast-enterprise/tags).

Please request trial license [here](https://hazelcast.com/hazelcast-enterprise-download/) or contact sales@hazelcast.com.

```
$ docker run -e HZ_LICENSE_KEY=<your_license_key> hazelcast/hazelcast-enterprise:$HAZELCAST_VERSION
```

### Hazelcast Enterprise Hello World

To run two Hazelcast nodes with Management Center, use the following commands.

```
$ docker run -p 8080:8080 hazelcast/management-center
$ docker run -p 5701:5701 -e HZ_LICENSE_KEY=<your_license_key> -e MANCENTER_URL="http://<host_ip>:8080/hazelcast-mancenter" -e JAVA_OPTS="-Dhazelcast.local.publicAddress=<host_ip>:5701" hazelcast/hazelcast-enterprise
$ docker run -p 5702:5701 -e HZ_LICENSE_KEY=<your_license_key> -e MANCENTER_URL="http://<host_ip>:8080/hazelcast-mancenter" -e JAVA_OPTS="-Dhazelcast.local.publicAddress=<host_ip>:5702" hazelcast/hazelcast-enterprise
```

Note that the `MANCENTER_URL` environment variable defines the address of the Management Center application. In this case, it is available at `http://<host_ip>:8080/hazelcast-mancenter`.

Now, if you open a browser at [http://localhost:8080/hazelcast-mancenter](http://localhost:8080/hazelcast-mancenter), you should see your cluster with 2 nodes. You can start the [client](https://github.com/hazelcast/hazelcast-code-samples/tree/master/clients/basic) and observe in Management Center that the map data has been added.

Read more about the Management Center image [here](https://github.com/hazelcast/management-center-docker).

## Hazelcast Defined Environment Variables

### MAX_HEAP_SIZE

You can give environment variables to the Hazelcast member within your Docker command. Currently, we support the variables  `MIN_HEAP_SIZE` and `MAX_HEAP_SIZE` inside our start script. An example command is as follows:

```
$ docker run -e MIN_HEAP_SIZE="1g" hazelcast/hazelcast
```

### JAVA_OPTS

As shown below, you can use `JAVA_OPTS` environment variable if you need to pass multiple VM arguments to your Hazelcast member.

```
$ docker run -e JAVA_OPTS="-Xms512M -Xmx1024M" hazelcast/hazelcast
```

### MANCENTER_URL

The address to the Management Center application can be defined using the `MANCENTER_URL` variable.

```
$ docker run -e MANCENTER_URL=<mancenter_url> hazelcast/hazelcast-enterprise
```

### HZ_LICENSE_KEY (Hazelcast Enterprise Only)

The license key for Hazelcast Enterprise can be defined using the `HZ_LICENSE_KEY` variable

```
$ docker run -e HZ_LICENSE_KEY=<your_license_key> hazelcast/hazelcast-enterprise
```

## Customizing Hazelcast

### Using Custom Hazelcast Configuration File

If you need to configure Hazelcast with your own `hazelcast.xml`, you need to mount the folder that has hazelcast.xml. You also need to pass the `hazelcast.xml` file path to `hazelcast.config` in `JAVA_OPTS` parameter. Please see the following example:

```
$ docker run -e JAVA_OPTS="-Dhazelcast.config=/opt/hazelcast/config_ext/hazelcast.xml" -v PATH_TO_LOCAL_CONFIG_FOLDER:/opt/hazelcast/config_ext hazelcast/hazelcast
```

### Extending CLASSPATH with new jars or files

Hazelcast has several extension points i.e MapStore API where you can provide your own implementation to add specific functionality into Hazelcast Cluster. If you have custom jars or files to put into classpath of docker container, you can simply use `CLASSPATH` environment variable and pass it via `docker run` command. Please see the following example:

```
$ docker run -e CLASSPATH="/opt/hazelcast/CLASSPATH_EXT/" -v PATH_TO_LOCAL_CONFIG_FOLDER:/opt/hazelcast/CLASSPATH_EXT hazelcast/hazelcast
```

### Extending Hazelcast Base Image

You can use Hazelcast Docker Image to start a new Hazelcast member with default configuration. If you'd like to customize your Hazelcast member, you can extend the Hazelcast base image, provide your own configuration file and customize your initialization process. In order to do that, you need to create a new `Dockerfile` and build it with `docker build` command. 

In the `Dockerfile` example below, we are creating a new image based on the Hazelcast image and adding our own configuration file from our host to the container, which is going to be used with Hazelcast when the container runs.

```
FROM hazelcast/hazelcast:$HAZELCAST_VERSION

# Adding custom hazelcast.xml
ADD hazelcast.xml ${HZ_HOME}
ENV JAVA_OPTS -Dhazelcast.config=${HZ_HOME}/hazelcast.xml
```

After creating the `Dockerfile` you need to build it by running the command below:

```
$ docker build .
```

Now you can run your own container with its ID or tag (if you provided `-t` option while building the image) using the `docker run` command.

## Graceful Shutdown

You can `stop` the member using the docker command: `docker stop <containerid>`.

By default, Hazelcast is configured to `TERMINATE` on receiving the SIGTERM signal from Docker, which means that a container stops quickly, but the cluster's data safety relies on the backup stored by other Hazelcast members.

The other option is to use the `GRACEFUL` shutdown, which triggers the partition migration before shutting down the Hazelcast member. Note that it may take some time depending on your data size. To use that approach, configure the following properties:

* Add `hazelcast.shutdownhook.policy=GRACEFUL` to your `JAVA_OPTS` environment variable
* Add `hazelcast.graceful.shutdown.max.wait=<seconds>` to your `JAVA_OPTS` environment variable
	* Default value is 600 seconds
* Stop the container using `docker stop --time <seconds>`
	* It defines how much time Docker waits before sending SIGKILL
	* Default value is 10 seconds
	* Value should be greater or equal `hazelcast.graceful.shutdown.max.wait`
	* Alternatively, you can configure the Docker timeout upfront by `docker run --stop-timeout <seconds>`

## Debugging, Managing, and Monitoring

You can debug and monitor Hazelcast instance running inside Docker container.

### Debugging

To debug your Hazelcast with the standard Java Tools support, use the following command to start Hazelcast container:

```
$ docker run -p 5005:5005 -e JAVA_TOOL_OPTIONS='-agentlib:jdwp=transport=dt_socket,server=y,suspend=n,address=5005' hazelcast/hazelcast
```

Now you can connect with your remote debugger using the address: `localhost:5005`.

### Managing and Monitoring

You can use the standard JMX protocol to monitor your Hazelcast instance. Start Hazelcast container with the following parameters.

```
$ docker run -p 9999:9999 -e JAVA_OPTS='-Dhazelcast.jmx=true -Dcom.sun.management.jmxremote.port=9999 -Dcom.sun.management.jmxremote.authenticate=false -Dcom.sun.management.jmxremote.ssl=false' hazelcast/hazelcast
```

Now you can connect using the address: `localhost:9999`.

## Docker Images Usages

### Hazelcast Docker Repositories

You can find all Hazelcast Docker Images on Docker Store Hazelcast Page.
https://store.docker.com/profiles/hazelcast

You can find Docker files by going to corresponding `hazelcast-docker` repo tag.
See the full list here: https://github.com/hazelcast/hazelcast-docker/releases

### Management Center

Please see [Management Center Repository](https://github.com/hazelcast/management-center-docker) for Dockerfile definitions and have a look at available images on [Docker Hub](https://store.docker.com/profiles/hazelcast) page.

### Hazelcast Kubernetes

Hazelcast is prepared to work in the Kubernetes environment. For details, please check:

* Hazelcast Helm Charts:
  * [Hazelcast IMDG](https://github.com/helm/charts/tree/master/stable/hazelcast)
  * [Hazelcast IMDG + Management Center](https://github.com/hazelcast/charts/tree/master/stable/hazelcast)
  * [Hazelcast IMDG Enterprise + Management Center](https://github.com/hazelcast/charts/tree/master/stable/hazelcast-enterprise)
* [Hazelcast Kubernetes Code Sample](https://github.com/hazelcast/hazelcast-code-samples/tree/master/hazelcast-integration/kubernetes)
* [Hazelcast SPI Kubernetes Plugin](https://github.com/hazelcast/hazelcast-kubernetes)

### Hazelcast Openshift

Hazelcast is prepared to work in the OpenShift environment. For details, please check:
* [Hazelcast OpenShift Quick Start](https://github.com/hazelcast/hazelcast-openshift)
* [Hazelcast OpenShift Code Sample](https://github.com/hazelcast/hazelcast-code-samples/tree/master/hazelcast-integration/openshift)
