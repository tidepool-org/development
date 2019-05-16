#!/bin/bash
kubectl get svc ambassador -o jsonpath={.status.loadBalancer.ingress[0].hostname}
