#!/bin/bash
kubectl get svc -o yaml --all-namespaces -l io.kompose.service=blip | grep host | sed -e "s/ *host: *//"
