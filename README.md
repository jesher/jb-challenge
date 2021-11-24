# Challenge
The challenge is create a Kubernetes cluster with this example application from Juro Baixo. The tools used was prometheus and grafana to show a dashboard with some metrics.

## Architecture

The infrastructure contains a Kubernetes(EKS) cluster with one instance on demand and two instances spot, also a NAT Gateway with one public subnet and a load balance network to access the cluster.

**Used:**
- Terraform v0.14.4

![Base Architecture](img/infra-aws.svg)

## Kubernetes

To install grafana, prometheus, jb-fizzbuzz and nginx-ingress(NLB) I used helmfile. Helmfile is a declarative spec for deploying helm charts

**Used:**
- Helm v3.6.3
- Helmfile v0.140.1

![helmfile](img/helmfile.svg)

## Getting started

The requirements are:
- Docker

Then, we need to set a few variables for Terraform:

```
export AWS_ACCESS_KEY_ID=<YOUR_AWS_ACCESS_KEY_ID>
export AWS_SECRET_ACCESS_KEY=<YOUR_AWS_SECRET_ACCESS_KEY>
```

1 - Cluster creation
```
make apply
```

2- Get URL and password for grafana login:

```
make grafana
```

3 - Destroy cluster
```
make destroy
```