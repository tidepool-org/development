#!/bin/bash
helm upgrade -f values-nocrd.yaml flux --repo https://weaveworks.github.io/flux flux
