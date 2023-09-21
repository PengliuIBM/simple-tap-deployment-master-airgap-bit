## Additional Development Namespaces

1. Fill out the `dev_namespaces` section of [tap-install-config](../../tap-install-config.yml).

2. Deploy with:

```bash
ytt --data-values-file ../../profiles/full/tap-install-config.yml -f . | kubectl apply -f-
```

3. You will still need to create the namespaces yourself. Namespace Provisioner does not create them for you.
