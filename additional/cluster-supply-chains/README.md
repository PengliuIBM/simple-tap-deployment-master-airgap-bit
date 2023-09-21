## NOTE: This file needs to be customized to your environment.
Notably, any mention of `harbor.tanzu.tacticalprogramming.com` or a repository of `tap/supply-chain` may need updating. The author regrets that this supply chain does not work as-is.

Alternatively, you can install the `basic` supply chain in your TAP, then export the supply chain that's been configured for your TAP with `kubectl get clustersupplychain source-to-url -o yaml` (or similar command), and apply that.

In TAP 1.6, you will need to add the following lines to the very bottom of the file in order to avoid "Multiple Supply Chain matches" errors.

```yaml
  - key: apps.tanzu.vmware.com/has-tests
    operator: DoesNotExist
```

