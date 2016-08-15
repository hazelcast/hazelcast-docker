# Table of Contents

* [Hazelcast](#hazelcast)
  * [Getting a Specific Hazelcast Version](#getting-a-specific-hazelcast-version)
  * [Starting and Stopping a Hazelcast Member](#starting-and-stopping-a-hazelcast-member)
  * [Setting Environment Variables](#setting-environment-variables)
  * [Using Hazelcast Configuration File](#using-hazelcast-configuration-file)
  * [Custom Configuration](#custom-configuration)
* [Hazelcast Enterprise](#hazelcast-enterprise)
* [Hazelcast Management Center](#hazelcast-management-center)
  * [Hazelcast Member Configuration](#hazelcast-member-configuration)
* [Hazelcast OpenShift](#hazelcast-openshift)
* [Hazelcast Docker Image Links](#hazelcast-docker-image-links)


You can deploy your Hazelcast projects using the Docker containers. Hazelcast has the following images on Docker:

* Hazelcast
* Hazelcast Enterprise
* Hazelcast Management Center
* Hazelcast OpenShift

# Hazelcast

You can pull the Hazelcast Docker image from Docker registry by running the following command:

```
docker pull hazelcast/hazelcast
```

Above command gets the latest stable Hazelcast release by default. After that you should be able to run the Hazelcast Docker image using the following command, which starts a Hazelcast member:

```
docker run -ti hazelcast/hazelcast
```

### Getting a Specific Hazelcast Version

You can also get a specific version of Hazelcast by specifying its tags. You can find the full list of Hazelcast tags at [Hazelcast tags](https://hub.docker.com/r/hazelcast/hazelcast/tags/).

An example command to get a specific Hazelcast version is as follows:

```
docker run -ti hazelcast/hazelcast:3.6-EA
```

### Starting and Stopping a Hazelcast Member

When you run the command `docker run -ti hazelcast/hazelcast`, it automatically runs the script `server.sh` and this  creates a new Hazelcast member.

You can `stop` the member using the script `stop.sh`. For this purpose, you need to run the following command to the running Docker container:

```
docker exec -it "id of running container" /opt/hazelcast/stop.sh
```

You can check the logs thereafter using the following command:

```
docker logs "id of running container"
```
 
### Setting Environment Variables

You can give environment variables to the Hazelcast member within your Docker command. Currently, we support the variables  `MIN_HEAP_SIZE` and `MAX_HEAP_SIZE` inside our start script. An example command is as follows:

```
docker run -e MIN_HEAP_SIZE="1g" -ti hazelcast/hazelcast
```

You can also define your environment variables inside a file as shown in the following example command:

```
docker run --env-file <file-path> -ti hazelcast/hazelcast
```

You can also define more than one VM arguments to your Hazelcast member via `JAVA_OPTS` environment variable. Please see the following example:

```
docker run -e JAVA_OPTS="-Xms512M -Xmx1024M -ti hazelcast/hazelcast
```

### Using Hazelcast Configuration File

In this case, you need to mount the folder that has the Hazelcast configuration file, i.e., `hazelcast.xml`. Also, while running the Docker image, you need to give the URL of `hazelcast.config` in `JAVA_OPTS` parameter. Please see the following example:

```
docker run -e JAVA_OPTS="-Dhazelcast.config=./configFolder/hazelcast.xml" -v ./configFolder:./configFolder -ti hazelcast/hazelcast
```

### Custom Configuration
You can use the Docker image to start a Hazelcast member with default configuration. If you like to customize your Hazelcast member, you can extend the Hazelcast base image, provide your own configuration file and customize your initialization process.

You need to create a new `Dockerfile` and build it in order to use it. In the `Dockerfile` example below, we are creating a new image based on the Hazelcast image and adding our own configuration file from our host to the container, which is going to be used with Hazelcast when the container runs.

```
FROM hazelcast:hazelcast/latest
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

# Hazelcast Enterprise

You can pull the Hazelcast Enterprise Docker image from the Docker registry by running the following command:

```
docker pull hazelcast/hazelcast-enterprise:latest
```

After that you should be able to run the Hazelcast Docker image using the following command:

```
docker run -ti -e HZ_LICENSE_KEY=YOUR_LICENSE_KEY hazelcast/hazelcast-enterprise:latest
```

# Hazelcast Management Center

You can pull the Hazelcast Management Center Docker image from the Docker registry by running the following command:

```
docker pull hazelcast/management-center:latest
```

After that you can run the Hazelcast Management Center Docker image using the following command:

```
docker run -ti -p 8080:8080 hazelcast/management-center:latest
```

Now you can reach Hazelcast Management Center from your browser using the URL `http://localhost:8080/mancenter`. 

If you are running the Docker image in the cloud, you should use a public IP of your machine instead of `localhost`. 

If you are using `docker-machine`, you can learn the Docker host IP using the following command:

```
docker-machine ls
```

If you are using `boot2docker`, you can learn the Docker host IP using the following command:

```
boot2docker ip
```

Then, you can run Hazelcast Management Center using the URL `http://host-ip:8080/mancenter`.

### Hazelcast Member Configuration

As a prerequisite, Hazelcast Cluster Member Containers should be launched with Management Center Enabled mode. This can be achieved by using a custom `hazelcast.xml` configuration file while launching the Hazelcast Member Container. For more information please refer to the [Using Hazelcast Configuration File](#using-hazelcast-configuration-file) section.

# Hazelcast OpenShift

First login to OpenShift using the OpenShift CLI with the following commands:

```
sudo su
oc login <your-openshit-login-url>
```

Then create a new project, e.g., `hazelcast-cluster`, and switch to that newly created using the following commands:

```
oc new-project hazelcast-cluster
oc project hazelcast-cluster 
```

Now download the project template from GitHub and use CLI to register the template under the newly created project using the following commands:

```
curl -o hazelcast-template.js https://raw.githubusercontent.com/hazelcast/hazelcast-docker/master/hazelcast-openshift/hazelcast-template.js
oc create -f hazelcast-template.js -n hazelcast-cluster
```

Finally, login to your OpenShift Web Administration UI. You should see your new Hazelcast template and start creating a Hazelcast cluster by filling the parameters according to your needs.

For detailed information please see our blog post at http://blog.hazelcast.com/openshift/.

# Hazelcast Docker Image Links

Hazelcast Open Source: https://hub.docker.com/r/hazelcast/hazelcast/

Hazelcast Enterprise: https://hub.docker.com/r/hazelcast/hazelcast-enterprise/

Hazelcast Management Center: https://hub.docker.com/r/hazelcast/management-center/

Hazelcast Openshift : https://hub.docker.com/r/hazelcast/openshift/


