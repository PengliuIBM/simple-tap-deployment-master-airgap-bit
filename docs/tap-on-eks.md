# TAP on EKS Requirements

This doc outlines what you need in order to succeed with TAP on EKS.

## Create EKS Cluster

We highly recommend using `eksctl`. Use this command as a starting point to create a sufficiently-sized cluster.

```sh
eksctl create cluster  \
--version=1.24 \
--node-type m5.xlarge \
--nodegroup-name tap-full-profile \
--nodes 3  \
--nodes-min 3 \
--nodes-max 10 \
--node-volume-size 100 \
--name=eks-us-east-2-tap-full
```

And install metrics server for basic quality-of-life functions.

```sh
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
```

## Install EBS Storage Drivers

TAP requires the installation of EBS Storage Drivers if you're using EKS as your k8s distro. Consult the docs for the latest. But for convenience, here is a quick gist of what commands to run to get you up and running.

These are current as of TAP 1.4. Again, consult the docs for the latest.

```sh
#
# Assuming we have an EKS cluster named 'eks-us-east-2-tap-full'
#

# check if we have an oidc provider already
oidc_id=$(aws eks describe-cluster --name eks-us-east-2-tap-full --query "cluster.identity.oidc.issuer" --output text | cut -d '/' -f 5)
aws iam list-open-id-connect-providers | grep $oidc_id | cut -d "/" -f4

# if no output, create one
eksctl utils associate-iam-oidc-provider --cluster eks-us-east-2-tap-full --approve

# need to create the EBS CSI driver IAM role and attach it to the cluster
eksctl create iamserviceaccount \
  --name ebs-csi-controller-sa \
  --namespace kube-system \
  --cluster eks-us-east-2-tap-full \
  --attach-policy-arn arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy \
  --approve \
  --role-only \
  --role-name AmazonEKS_EBS_CSI_DriverRole

#
# NOTE: If you use custom KMS keys for EBS encryption, there's additional work. See the docs.
#

# fetch details of the newly-created IAM account/role. You'll need them when you install the driver.
eksctl get iamserviceaccount --cluster eks-us-east-2-tap-full

# finally, install the driver
eksctl create addon --name aws-ebs-csi-driver --cluster eks-us-east-2-tap-full  --service-account-role-arn arn:aws:iam::$account_id_from_the_above_command:role/AmazonEKS_EBS_CSI_DriverRole 

# Follow these docs to test if the driver installed successfully.
https://docs.aws.amazon.com/eks/latest/userguide/ebs-sample-app.html
```

## Relevant AWS Docs

Docs on EBS CSI driver https://docs.aws.amazon.com/eks/latest/userguide/managing-ebs-csi.html

Docs on creating an OIDC provider for your EKS cluster https://docs.aws.amazon.com/eks/latest/userguide/enable-iam-roles-for-service-accounts.html

Docs on IAM roles necessary https://docs.aws.amazon.com/eks/latest/userguide/csi-iam-role.html
