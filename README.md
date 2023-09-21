# Simple Tanzu App Platform (TAP) Deployment

## Goal
This repo helps you deploy TAP onto your Kubernetes cluster.

## Assumptions
This repo assumes you already have a Kubernetes cluster with all prereqs take care of. See the [TAP prereqs docs](https://docs.vmware.com/en/VMware-Tanzu-Application-Platform/1.5/tap/prerequisites.html#kubernetes-cluster-requirements-3) for the prereqs for your Kubernetes distribution. 

As part of the prereqs, you'll need Tanzu Cluster Essentials installed as well. See [the Cluster Essentials Docs](https://docs.vmware.com/en/Cluster-Essentials-for-VMware-Tanzu/index.html) for the latest.


## How Does it Work?
At the root of this repo are two files:

- [tap-install-config.yml.example](tap-install-config.yml.example)
- [tap-install-secrets.yml.example](tap-install-secrets.yml.example)

Copy each of those files to new files (removing the `.example`), and fill in the details for your installation. The files are commented to guide you along the way.

The example config is already configured to give you a `full` profile with self-signed TLS certs.

After deployment, you will still need to configure DNS. This can be done either manually or via `external-dns`. The config includes sections to uncomment to make use of external-dns.

## Installing
After filling out the config and secrets files, run `./install-tap.sh` to deploy TAP.

## Downloading for Airgapped Installations
This repo includes [a script](./download-bits.sh) for downloading software necessary for installing TAP airgapped. See [the doc](./docs/downloading-files.md) for details.