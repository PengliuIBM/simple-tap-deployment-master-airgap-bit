# Downloading Files for TAP

Use [download-bits.sh](../download-bits.sh) to download the necessary bits for a TAP installation, including CLI utilities.

The script creates a directory, `bits-for-transfer`, and places all downloaded files in there.

Please note:
* The TAP and TBS deps versions are hardcoded. You will need to update them to match your needs.
* The script assumes you are already logged into TanzuNet.
* TAP and the TBS deps are _large_. Upwards of 20GB when combined. Plan accordingly.

## Retries and failures
TanzuNet is known to have issues with TLS and uptime, resulting in what may appear to be `imgpkg` TLS failures when, in fact, it's TanzuNet. A way to get around this problem is to simply re-run the script, re-trying on failure, until the script exits successfully. You can do that with the following one-liner:

```sh
while true; do 'attempting to download'; ./download-bits.sh all && break; done
```

This will:
* Only download the CLI utilities one time. If you already have them, it will not download them again.
* Catch any failures and re-run the script.
* Stop running once the script exits successfully.

## Uploading images to your registry
See [the docs for airgapped deploys](https://docs.vmware.com/en/VMware-Tanzu-Application-Platform/1.5/tap/install-air-gap.html) for exact commands. 

As a helper, the download script also downloads a copy of the TAP docs in PDF form for you.

Here's the sample `imgpkg` command for uploading images to your registry, from the docs:

```sh
imgpkg copy \
  --tar tap-packages-$TAP_VERSION.tar \
  --to-repo $IMGPKG_REGISTRY_HOSTNAME/tap-packages \
  --include-non-distributable-layers \
  --registry-ca-cert-path $REGISTRY_CA_PATH
```