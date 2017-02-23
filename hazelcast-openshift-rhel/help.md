% HAZELCAST(1) RHEL7 Container Image Pages
% Hazelcast, Inc.
% November 23, 2016


# DESCRIPTION

This image simplifies the deployment of a Hazelcast based standalone infrastructure. As a certified
Red Hat Enterprise Linux based image it is built on top of RHEL 7. 

This package consists of the following parts:

 * Hazelcast
 * Red Hat Enterprise Linux (RHEL) 7
 * Oracle Java 8
 * Hazelcast Kubernetes Discovery
 * k8i backend for kubernetes discovery


# USAGE

The easiest way to install, update and run the Hazelcast image is using the atomic CLI as shown in the
following examples:

To set up the host system for use by the Hazelcast container, run:

  atomic install hazelcast/hazelcast-openshift:rhel7

To run the Hazelcast container (after it is installed), run:

  atomic run hazelcast/hazelcast-openshift:rhel7

To remove the Hazelcast container (not the image) from your system, run:

  atomic uninstall hazelcast/hazelcast-openshift:rhel7

To upgrade the Hazelcast container from your system, run:

  atomic upgrade hazelcast/hazelcast-openshift:rhel7


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


