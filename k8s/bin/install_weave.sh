#!/bin/bash
helm install --namespace flux -f values.yaml --repo https://weaveworks.github.io/flux flux
