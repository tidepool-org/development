# Service Guide

Installed in this cluster are a number of support services.

- cert-manager - installs and rotates TLS certificates
- gloo - routes traffic to services (i.e. the API Gateway)
- external-dns - publishes DNS entries for services in the cluster
- kiam - assigns AWS IAM Roles to pods
- load-balancer - creates an external AWS load balancer
- fluxcloud - publishes cluster changes to a Slack channel
