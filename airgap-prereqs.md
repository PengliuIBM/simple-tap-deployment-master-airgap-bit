# Airgapped Pre-Requisites

This doc is here to help navigate the documentation before an airgapped install of TAP.  

CLI Tools:
- [k9s](https://k9scli.io/)
- kubectl plugins (installed w/ krew): [view-allocations](https://github.com/davidB/kubectl-view-allocations), [view-utilization](https://github.com/etopeter/kubectl-view-utilization), [tree](https://github.com/ahmetb/kubectl-tree)
- [Tanzu CLI](https://docs.vmware.com/en/VMware-Tanzu-Application-Platform/1.5/tap/install-tanzu-cli.html) with all plugins 
- [Carvel tools](https://carvel.dev/) ytt, kctrl, at least
- [yq](https://github.com/mikefarah/yq)

Migrate containers and files to an airgapped network
- [Cluster Essentials Containers](https://docs.vmware.com/en/Cluster-Essentials-for-VMware-Tanzu/1.5/cluster-essentials/deploy.html#install-2)
- [TAP Containers](https://docs.vmware.com/en/VMware-Tanzu-Application-Platform/1.5/tap/install-air-gap.html#relocate-images-to-a-registry-0)
- [Grype Database](https://github.com/anchore/grype#offline-and-air-gapped-environments)
- Tanzu Build Service (TBS) [Full Dependencies](https://docs.vmware.com/en/VMware-Tanzu-Application-Platform/1.5/tap/tbs-offline-install-deps.html)