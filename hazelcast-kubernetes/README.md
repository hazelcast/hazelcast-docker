#### FIXME Work in progress

Edit `hz-config.yaml` configuration file and install it:

    $ kubectl apply -f hz-config.yaml

Deploy Hazelcast:

    $ kubectl apply -f hazelcast-service.yaml

##### Optional

Readiness probe:

    readinessProbe:
      exec:
        command:
        - "./readiness.sh"
      initialDelaySeconds: 35
      timeoutSeconds: 5
      periodSeconds: 10
