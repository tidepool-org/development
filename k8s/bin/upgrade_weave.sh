#!/bin/bash
helm upgrade --namespace flux -f values-nocrd.yaml flux --repo https://weaveworks.github.io/flux flux
