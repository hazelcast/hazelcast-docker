# Hazelcast Docker Image

This repo contains docker image for [Hazelcast](http://hazelcast.org) open-source in-memory data-grid.


# Usage

You need to pull hazelcast docker image from Docker registry via command below : 

```
docker pull hazelcast/hazelcast
```

After that you should be able to run Hazelcast docker image by : 

```
docker run -ti hazelcast/hazelcast
```

# Custom configuration

You can use docker image to start Hazelcast instance with default configuration. If you'd like to customize your  hazelcast instance you can extend the hazelcast base image, provide your own configuration file and customize your initialization process.


## Extending the image

You need to create a new `Dockerfile` and build it in order to be able to use it. In the `Dockerfile` example below we are creating a new image based on Hazelcast image and adding our own configuration file, from our host to the container,  which is going to be used with Hazelcast when the container runs.

```
FROM hazelcast:latest
# Add your custom hazelcast.xml
ADD hazelcast.xml $HZ_HOME
# Run hazelcast
CMD java -cp $HZ_HOME/hazelcast-$HZ_VERSION.jar com.hazelcast.core.server.StartServer
```

After creating the `Dockerfile` you need to build it. You can build your `Dockerfile` with the command below : 

```
docker build .
```

After that you need to be able to run your own container with id or tag (if you provided `-t` option while building the image) with `docker run` command.

# Issues

Please report issues regarding to Hazelcast docker image by creating github issues on this repository.

# Enhancements

If you'd like to make contribution to Hazelcast docker image please feel free to create a pull request.
