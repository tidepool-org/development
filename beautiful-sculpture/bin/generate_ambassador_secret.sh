#!/bin/bash
DIR= /Users/derrickburns/go/src/github.com/tidepool-org/dev-ops/k8s/shared
kubectl create -n default secret tls ambassador-certs --key=${DIR}/tidepool-key.pem --cert=${DIR}/tidepool-cert.pem 
