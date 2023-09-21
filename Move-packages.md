# Move TAP Packages to Your Own Repo

This is 100% ripped from the docs, but kept here as a quick reference.

Before running anything here, make sure you can `docker login` to both your destination repo, and `registry.tanzu.vmware.com`.

Move cluster essentials (optional)
```bash
TAP_REGISTRY_HOST=us-east4-docker.pkg.dev/my-repo/tap
# Find this under "tap-package-repo-bundle" in the appropriate version
# This SHA is for TAP 1.4.0
CLUSTER_ESSENTIALS_BUNDLE_SHA256=645a0ef892ef9aa2d7534e368bd33792fa1929df6bed2223a582cf0a7e9fd4ac

imgpkg copy \
  -b registry.tanzu.vmware.com/tanzu-cluster-essentials/cluster-essentials-bundle@sha256:$CLUSTER_ESSENTIALS_BUNDLE_SHA256 \
  --to-repo $TAP_REGISTRY_HOST/cluster-essentials-bundle \
  --include-non-distributable-layers
```

Move TAP Images
```bash
TAP_VERSION=1.4.0

imgpkg copy \
   -b registry.tanzu.vmware.com/tanzu-application-platform/tap-packages:${TAP_VERSION} \
   --to-repo ${TAP_REGISTRY_HOST}/tap-packages \
   --include-non-distributable-layers
```

Move the Full TBS Packages
```bash
TBS_VERSION=1.9.0

imgpkg copy -b registry.tanzu.vmware.com/tanzu-application-platform/full-tbs-deps-package-repo:${TBS_VERSION} \
  --to-repo us-east4-docker.pkg.dev/mosher-workspace/tap/tbs-full-deps
```
