#!/bin/bash
DIR= /Users/derrickburns/go/src/github.com/tidepool-org/dev-ops/k8s/shared
kubectl create -n istio-system secret generic tidepool-org --from-file=key=${DIR}/tidepool-key.pem --from-file=cert=${DIR}/tidepool-cert.pem 
