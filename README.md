# Hazelcast Docker

This repository contains Dockerfiles for the official Hazelcast Docker images.

## Quick Start

### Hazelcast

You can launch a Hazelcast Docker Container by running the following command. Check [Hazelcast Versions](#hazelcast-versions) for the versions to replace $HAZELCAST_VERSION.

```
$ docker run hazelcast/hazelcast:$HAZELCAST_VERSION
```
This command will pull a Hazelcast Docker image and run a new Hazelcast instance.

### Hazelcast Versions

You can find the full list of Hazelcast versions at the [Official Hazelcast Docker Hub](https://store.docker.com/community/images/hazelcast/hazelcast/tags).


### Hazelcast Hello World

For the simplest end-to-end scenario, you can create a Hazelcast cluster with two Docker containers and access it from the client application.

```
$ docker run -e HZ_NETWORK_PUBLICADDRESS=<host_ip>:5701 -p 5701:5701 hazelcast/hazelcast:$HAZELCAST_VERSION
$ docker run -e HZ_NETWORK_PUBLICADDRESS=<host_ip>:5702 -p 5702:5701 hazelcast/hazelcast:$HAZELCAST_VERSION
```

Note that:
* each container must publish the `5701` port under a different host machine port (`5701` and `5702` in the example)
* supplying a custom `HZ_NETWORK_PUBLICADDRESS` is critical for autodiscovery. Otherwise, Hazelcast will bind to Docker's internal ports.
* `<host_ip>` needs to be the host machine address that will be used for the Hazelcast communication

After setting up the cluster, you can start the [client](https://github.com/hazelcast/hazelcast-code-samples/tree/master/clients/basic) application to check if it works correctly.

### Hazelcast Enterprise

You can launch a Hazelcast Enterprise Docker Container by running the following command. Check [Hazelcast Enterprise Versions](#hazelcast-enterprise-versions) for the versions to replace $HAZELCAST_VERSION.

Please request a trial license [here](https://hazelcast.com/hazelcast-enterprise-download/) or contact sales@hazelcast.com.

```
$ docker run -e HZ_LICENSEKEY=<your_license_key> hazelcast/hazelcast-enterprise:$HAZELCAST_VERSION
```

### Hazelcast Enterprise Versions

You can find the full list of Hazelcast Enterprise versions at the [Official Hazelcast Docker Hub](https://store.docker.com/community/images/hazelcast/hazelcast-enterprise/tags).

### Hazelcast Enterprise Hello World

To run two Hazelcast nodes, use the following commands.

```
$ docker run -p 5701:5701 -e HZ_LICENSEKEY=<your_license_key> -e HZ_NETWORK_PUBLICADDRESS=<host_ip>:5701 hazelcast/hazelcast-enterprise:$HAZELCAST_VERSION
$ docker run -p 5702:5701 -e HZ_LICENSEKEY=<your_license_key> -e HZ_NETWORK_PUBLICADDRESS=<host_ip>:5702 hazelcast/hazelcast-enterprise:$HAZELCAST_VERSION
```

Note that:
* This example assumes unencrypted communication channels for Hazelcast members and clients. Hazelcast allows you to encrypt socket-level communication between Hazelcast members and between Hazelcast clients and members. Refer to [this section](https://github.com/hazelcast/hazelcast-docker#tls_enabled-hazelcast-enterprise-only) to learn about enabling TLS/SSL encryption.

### Management Center Hello World

Whether you started the Hazelcast or Hazelcast Enterprise cluster, you could use the Management Center application to monitor and manage your cluster.

```
docker run \
  -e MC_INIT_CMD="./mc-conf.sh cluster add -H=/data -ma <host_ip>:5701 -cn dev" \
  -p 8080:8080 hazelcast/management-center:$MANAGEMENT_CENTER_VERSION
```

Now, you can access Management Center from your browser using the following URL: `https://localhost:8080`. You can read more about the Management Center Docker image [here](https://github.com/hazelcast/management-center-docker).

Note that the way the Management Center is started changed since Hazelcast 4.0. If you use Hazelcast 3.x, please find the instructions [here](https://github.com/hazelcast/hazelcast-docker/tree/3.12.z).

## Hazelcast Defined Environment Variables

### JAVA_OPTS

As shown below, you can use `JAVA_OPTS` environment variable if you need to pass multiple VM arguments to your Hazelcast member.

```
$ docker run -e JAVA_OPTS="-Xms512M -Xmx1024M" hazelcast/hazelcast
```

### PROMETHEUS_PORT

The port of the JMX Prometheus agent. For example, if you set `PROMETHEUS_PORT=8080`, then you can access metrics at: `http://<hostname>:8080/metrics`. You can also use `PROMETHEUS_CONFIG` to set a path to the custom configuration.

### LOGGING_LEVEL

The logging level can be changed using the `LOGGING_LEVEL` variable, for example, to see the `DEBUG` logs.

```
$ docker run -e LOGGING_LEVEL=DEBUG hazelcast/hazelcast
```

Available logging levels are (from highest to lowest): `OFF`, `FATAL`, `ERROR`, `WARN`, `INFO`, `DEBUG`, `TRACE` and `ALL`. The default logging level is `INFO`. Invalid levels will be assumed `OFF`.

Note that if you need some more custom logging configuration, you can specify a configuration file.

```
$ docker run -v <config-file-path>:/opt/hazelcast/config/log4j2.properties hazelcast/hazelcast
```

### LOGGING_CONFIG

_since version 5.1_

The logging configuration can be changed using the `LOGGING_CONFIG` variable, for example you can mount your own Log4j2 configuration file and set the path using this variable.
The default value is set to `/opt/hazelcast/config/log4j2.properties`.
A relative or an absolute path can be provided.

We also provide `log4j2-json.properties` file in the image. This is using the Log4j2 [log4j-layout-template-json](https://logging.apache.org/log4j/2.x/manual/json-template-layout.html) module. To use it you can do the following:

```
$ docker run -e LOGGING_CONFIG=log4j2-json.properties hazelcast/hazelcast
```

See the [Log4j2 manual](https://logging.apache.org/log4j/2.x/manual/) for reference.

## Customizing Hazelcast

### Memory

Hazelcast Docker image respects the container memory limits, so you can specify it with the `-m` parameter.

```
$ docker run -m 512M hazelcast/hazelcast:$HAZELCAST_VERSION
```

Note that by default Hazelcast uses up to 80% of the container memory limit, but you can configure it by adding `-XX:MaxRAMPercentage` to the `JAVA_OPTS` variable.

### Configuring Hazelcast via Environment Variables

Configuration entries of your cluster can be overritten without changing the declarative configuration files (XML/YAML), see [Overriding Configuration documentation section](https://docs.hazelcast.com/hazelcast/latest/configuration/configuring-with-system-properties).

Assume that you want to have the following configuration for your cluster, represented as YAML:
```yaml
hazelcast:
  cluster-name: dev
  network:
    port:
      auto-increment: true
      port-count: 100
      port: 5701
```

If you want to use the environment variables, the above would be represented as a set of the following environment variables:
```bash
$ docker run -e HZ_CLUSTERNAME=dev \
  -e HZ_NETWORK_PORT_AUTOINCREMENT=true \
  -e HZ_NETWORK_PORT_PORTCOUNT=100 \
  -e HZ_NETWORK_PORT_PORT=5701 \
  hazelcast/hazelcast
```

### Using Custom Hazelcast Configuration File

If you need to configure Hazelcast with your own `hazelcast.yaml` (or `hazelcast.xml`), you can mount the host folder which contains Hazelcast configuration and pass `hazelcast.config` JVM property. For example, assuming you placed Hazelcast configuration as `/home/ubuntu/hazelcast/hazelcast.yaml`, you can execute the following command.

```
$ docker run -e JAVA_OPTS="-Dhazelcast.config=/opt/hazelcast/config_ext/hazelcast.yaml" -v /home/ubuntu/hazelcast:/opt/hazelcast/config_ext hazelcast/hazelcast
```

Alternatively, you can [extend Hazelcast base image](#extending-hazelcast-base-image) adding your Hazelcast configuration file.

### Extending CLASSPATH with new jars or files

Hazelcast has several extension points i.e MapStore API where you can provide your own implementation to add specific functionality into Hazelcast Cluster. If you have custom jars or files to put into classpath of docker container, you can simply use Docker volume and use `CLASSPATH` environment variable in the `docker run` command. For example, assuming you placed your custom JARs into `/home/ubuntu/hazelcast/`, you can execute the following command.

```
$ docker run -e CLASSPATH="/opt/hazelcast/CLASSPATH_EXT/*" -v /home/ubuntu/hazelcast:/opt/hazelcast/CLASSPATH_EXT hazelcast/hazelcast
```

Alternatively, you can [extend Hazelcast base image](#extending-hazelcast-base-image) adding your custom JARs.


### Using TLS (Hazelcast Enterprise Only)

The `HZ_NETWORK_SSL_ENABLED` environment variable can be used to enable TLS for the communication. The key material folder should be mounted and properly referenced by using `JAVA_OPTS` variable.

1. Generate a sample key material (self-signed certificate)
```bash
$ mkdir keystore
$ keytool -validity 365 -genkeypair -alias server -keyalg EC -keystore ./keystore/server.keystore -storepass 123456 -keypass 123456 -dname CN=localhost
$ keytool -export -alias server -keystore ./keystore/server.keystore -storepass 123456 -file ./keystore/server.crt
$ keytool -import -noprompt -alias server -keystore ./keystore/server.truststore -storepass 123456 -file ./keystore/server.crt
```

2. Run Hazelcast Enterprise with TLS enabled:
```bash
$ docker run -e HZ_LICENSEKEY=<your_license_key> \
    -e HZ_NETWORK_SSL_ENABLED=true \
    -v `pwd`/keystore:/keystore \
    -e "JAVA_OPTS=-Djavax.net.ssl.keyStore=/keystore/server.keystore -Djavax.net.ssl.keyStorePassword=123456
    -Djavax.net.ssl.trustStore=/keystore/server.truststore -Djavax.net.ssl.trustStorePassword=123456" \
    hazelcast/hazelcast-enterprise
```

### Extending Hazelcast Base Image

If you'd like to customize your Hazelcast member, you can extend the Hazelcast base image and provide your configuration file or/and custom JARs. To do that, you need to create a new `Dockerfile` and build it with `docker build` command.

In the `Dockerfile` example below, we are creating a new image based on the Hazelcast image and adding our configuration file and a custom JAR from our host to the container, which will be used with Hazelcast when the container runs.

```
FROM hazelcast/hazelcast:$HAZELCAST_VERSION

# Adding custom hazelcast.yaml
ADD hazelcast.yaml ${HZ_HOME}
ENV JAVA_OPTS -Dhazelcast.config=${HZ_HOME}/hazelcast.yaml

# Adding custom JARs to the classpath
ADD custom-library.jar ${HZ_HOME}
```

## Graceful Shutdown

You can `stop` the member using the docker command: `docker stop <containerid>`.

By default, Hazelcast is configured to `TERMINATE` on receiving the SIGTERM signal from Docker, which means that a container stops quickly, but the cluster's data safety relies on the backup stored by other Hazelcast members.

The other option is to use the `GRACEFUL` shutdown, which triggers the partition migration before shutting down the Hazelcast member. Note that it may take some time, depending on your data size. To use that approach, configure the following properties:

* Add `hazelcast.shutdownhook.policy=GRACEFUL` to your `JAVA_OPTS` environment variable
* Add `hazelcast.graceful.shutdown.max.wait=<seconds>` to your `JAVA_OPTS` environment variable
	* Default value is 600 seconds
* Stop the container using `docker stop --time <seconds>`
	* It defines how much time Docker waits before sending SIGKILL
	* Default value is 10 seconds
	* Value should be greater or equal `hazelcast.graceful.shutdown.max.wait`
	* Alternatively, you can configure the Docker timeout upfront by `docker run --stop-timeout <seconds>`

You can debug and monitor Hazelcast instances running inside Docker containers.

## Managing and Monitoring

You can use JMX or Prometheus for application monitoring.

### JMX

You can use the standard JMX protocol to monitor your Hazelcast instance. Start a Hazelcast container with the following parameters.

```
$ docker run -p 9999:9999 -e JAVA_OPTS='-Dhazelcast.jmx=true -Dcom.sun.management.jmxremote.port=9999 -Dcom.sun.management.jmxremote.authenticate=false -Dcom.sun.management.jmxremote.ssl=false' hazelcast/hazelcast
```

Now you can connect using the address: `localhost:9999`.

### Prometheus

You can use the JMX Prometheus agent and expose JVM and JMX Hazelcast metrics.

```
$ docker run -p 8080:8080 -e PROMETHEUS_PORT=8080
```

Then, the metrics are available at: `http://localhost:8080/metrics`. Note that you can add also `-e JAVA_OPTS='-Dhazelcast.jmx=true'` to expose JMX via Prometheus (otherwise, just JVM metrics are visible).

## Debugging

### Remote Debugger

To debug your Hazelcast with the standard Java Tools support, use the following command to start Hazelcast container:

```
$ docker run -p 5005:5005 -e JAVA_TOOL_OPTIONS='-agentlib:jdwp=transport=dt_socket,server=y,suspend=n,address=*:5005' hazelcast/hazelcast
```

Now you can connect with your remote debugger using the address: `localhost:5005`.

### Building Your Hazelcast Image

You may want to build your own Hazelcast Docker image with some custom JARs. For example, if you want to test if your change in the Hazelcast Root repository works fine in the Kubernetes environment or you just need to use an entry processor JAR. To do it, place your JARs into the current directory, build the image, and push it into the Docker registry.

Taking our first example, imagine you did some change in the Hazelcast Root repository and would like to test it on Kubernetes. You need to build `hazelcast-SNAPSHOT.jar` and then do the following.

```
$ cd hazelcast-oss
$ cp <path-to-hazelcast-jar> ./
$ docker build -t <username>/hazelcast:test .
$ docker push <username>/hazelcast:test
```

Then, use the image `<username>/hazelcast:test` in your Kubernetes environment to test your change.

Additional documentation can be found [here](https://hazelcast.atlassian.net/wiki/spaces/DI/pages/5110693890/How+to+build+local+Hazelcast+Docker+image+from+hazelcast-mono).

## Docker Images Usages

### Hazelcast Docker Repositories

You can find all Hazelcast Docker Images on Docker Store Hazelcast Page.
https://store.docker.com/profiles/hazelcast

You can find Docker files by going to the corresponding `hazelcast-docker` repo tag.
See the full list here: https://github.com/hazelcast/hazelcast-docker/releases

### Management Center

Please see [Management Center Repository](https://github.com/hazelcast/management-center-docker) for Dockerfile definitions and have a look at available images on [Docker Hub]([https://store.docker.com/profiles/hazelcast](https://hub.docker.com/r/hazelcast/management-center) page.

### Hazelcast Kubernetes

Hazelcast is prepared to work in the Kubernetes environment. For details, please check:

* [Hazelcast Platform Operator](https://github.com/hazelcast/hazelcast-platform-operator)
* Hazelcast Helm Charts:
  * [Hazelcast](https://github.com/hazelcast/charts/tree/master/stable/hazelcast)
  * [Hazelcast Enterprise](https://github.com/hazelcast/charts/tree/master/stable/hazelcast-enterprise)

### Automatic rebuilding (Hazelcast Enterprise only)

Every 24 hours maintained Hazelcast Enterprise docker images are checked against updates of the base system or system libraries. If any of them are present the images are rebuilt and republished.
