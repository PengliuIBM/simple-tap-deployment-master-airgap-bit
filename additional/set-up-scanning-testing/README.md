Set up dev namespaces to use the scanning_testing pipeline.

1. Create the additional developer namespaces with the [dev-namespaces](../dev-namespaces/) manifests.

1. Deploy with:
```sh
ytt --data-values-file ../../tap-install-config.yml -f . | kapp deploy --wait-check-interval 10s -a scanning-testing-deps  -f- --yes
```