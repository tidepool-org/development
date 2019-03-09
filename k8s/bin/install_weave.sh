#!/bin/bash
VALUESFILE=${1:-values.yaml}
helm install --namespace flux -f ${VALUESFILE} --repo https://weaveworks.github.io/flux flux
