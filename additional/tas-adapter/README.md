 # TAS Adapter

Assumptions:
 - you have the TAS Adapter packages located in the same registry as TAP
 - You will use the same registry creds to install TAS adapter
 - you have already installed TAP to the `tap-install` namespace
 - You know that your version of TAP has the [correct packages](https://docs.vmware.com/en/Application-Service-Adapter-for-VMware-Tanzu-Application-Platform/1.1/tas-adapter/install-prerequisites.html) for TAS Adapter.  If installing next to a Full TAP profile, you're good. 
 - You are going to use the shared cert in `certificates/certificate.yml`, which defines the following domains for TAS adapter:
     - `cf-apps.<domain>`
     - `cf-api.<domain>`

Install:
 - `cp tas-adapter-config.yml.example tas-adapter-config.yml`
 - Ensure you agree with the above assumptions
 - Install from this directory with `./install.sh`