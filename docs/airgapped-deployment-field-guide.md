# Airgapped Deployment Field Guide

This document is a living document meant to capture lessons learned from events in the field. You should glance through this document before deploying in an airgapped scenario.

### k8s worker nodes need at least 100GB of storage
Build Service uses a lot of space. The worker nodes need extra storage, else you will get odd, silent failures on app deployments.

TODO: How is this done for TKG(s|m)?

### Cluster Essentials needs the custom CA installed
It's easy to miss, but the docs tell you how to do this. Don't install Cluster Essentials without configuring your CA first.

### (TKGs) PSP need to be configured.
You need to configure the PSP (future: probably PSA, Pod Security Admission Controller?)

### Ensure the k8s cluster has a default StorageClass
The Metadata Store will fail because it needs a volume to back the database. 

### Put an empty line at the end of the CA for TBS
IDK why. Just do it and save yourself the hour of time.
