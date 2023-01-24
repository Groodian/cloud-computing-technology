# Group A 2

## Infrastructure
The folder [infrastructure](infrastructure/) contains terraform files to deploy the infrastructure.

## Kubernetes Install
The folder [kubernetes-install](kubernetes-install/) contains ansible scripts to deploy the kubernetes cluster to the deployed infrastructure.

## Kubernetes Deploy
The folder [kubernetes-deploys](kubernetes-deploys/) contains terraform files to deploy applications like prometheus to the kubernetes cluster.

## Connect to a node example
```
ssh -o StrictHostKeyChecking=no -oUserKnownHostsFile=/dev/null -o IdentityFile=infrastructure/.ssh/cluster -o ProxyCommand="ssh -o StrictHostKeyChecking=no -oUserKnownHostsFile=/dev/null -o IdentityFile=infrastructure/.ssh/bastion -W %h:%p bastion@34.159.117.57" kube@10.156.0.5
```
