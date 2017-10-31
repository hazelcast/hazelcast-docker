#### FIXME Work in progress

Create a secret for your license key:

    $ kubectl create secret generic hz-ee-license --from-literal=key=LICENSE-KEY-HERE

Edit `hz-ee-config.yaml` configuration file and install it:

    $ kubectl apply -f hz-ee-config.yaml

Deploy Hazelcast EE:

    $ kubectl apply -f hazelcast-ee-service.yaml
