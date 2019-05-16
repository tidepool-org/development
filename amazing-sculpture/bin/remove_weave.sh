#!/bin/bash

kubectl delete crd fluxhelmreleases.helm.integrations.flux.weave.works 2>/dev/null
kubectl delete crd helmreleases.flux.weave.works 2>/dev/null
helm del --purge flux 2>/dev/null
