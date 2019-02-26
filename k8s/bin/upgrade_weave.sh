#!/bin/bash
helm upgrade --namespace flux -f values.yaml flux --repo https://weaveworks.github.io/flux flux
