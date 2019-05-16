#!/bin/bash
# Install of upgrade Weave Flux
#
# If run within the a Git repo, it will use the remote origin repo as the source repo and the current branch as the source branch.

rp=$(git rev-parse --is-inside-work-tree 2>/dev/null)
if [ "${rp}" = "true" ]
then
    CURRENT_BRANCH=$(git branch | grep \* | cut -d ' ' -f2)
    CURRENT_REPO=$(git config --get remote.origin.url)
fi

CRDS_UNINSTALLED=$(kubectl get crds helmreleases.flux.weave.works >/dev/null; echo $?)
if [ ${CRDS_UNINSTALLED} -eq 0 ]
then
    INSTALL_CRDS=false
else
    INSTALL_CRDS=true
fi

SOURCE_BRANCH=${2:-${CURRENT_BRANCH}}
SOURCE_PATH=${3:-k8s}
SOURCE_REPO=${4:-${CURRENT_REPO}}

read -p "Install weave: install_crds=${INSTALL_CRDS} branch=${SOURCE_BRANCH} path=${SOURCE_PATH} repo=${SOURCE_REPO}? (y|N)  " -n 1 -r
if [[ $REPLY =~ ^[Yy]$ ]]
then
    helm upgrade  \
      -i flux \
      --repo https://weaveworks.github.io/flux \
      --set rbac.create=true \
      --set helmOperator.create=true \
      --set helmOperator.chartsSyncInterval=1m \
      --set helmOperator.replicaCount=1 \
      --set helmOperator.updateChartDeps=true \
      --set helmOperator.createCRD=${INSTALL_CRDS} \
      --set git.url=${SOURCE_REPO} \
      --set git.path=${SOURCE_PATH} \
      --set git.branch=${SOURCE_BRANCH} \
      --set git.pollInterval=1m \
      --set git.timeoout=40s \
      flux
else
	echo "No action taken."
fi
