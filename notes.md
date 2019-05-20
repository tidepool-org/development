# set up new cluster running the Tidepool services
####install cli tools
```
brew install eksctl
brew install fluxctl
brew install kubernetes-helm
brew install kubernetes-cli
```

#### *MANUAL*: # create GitHub access key and store in `~/.secrets/github_access_token`

#### install tiller
```
kubectl -n kube-system create sa tiller
kubectl create clusterrolebinding tiller-cluster-rule --clusterrole=cluster-admin --serviceaccount=kube-system:tiller
```

#### each time you upgrade the helm client tools, you must upgrade the tiller client as well
#### this command can be used both for the initial install of helm and subsequent upgrades
`helm init --skip-refresh --upgrade --service-account tiller --history-max 200`

#### create cluster
```
cd clusters
mkdir $CLUSTER_NAME
cd $CLUSTER_NAME
```
#### this command will create a 5 node cluster and save the configuration in a local file
#### this will take about 10-15 minutes
`eksctl create cluster --name $CLUSTER_NAME --nodes-min 5 --nodes-max=6 --region=us-west-2 --kubeconfig=./kubeconfig.yaml`

`BIN="dev-ops/bin"`

#### install Weave flux (from within the cluster subdirectory)
`$BIN/install_weave`

#### install deploy key into branch w/ write access so that weave can update the cluster
`$BIN/push_deploy_key`

#### update aws-auth configmap to add tidepool ops users
`$BIN/install_users`

#### set DNS routes
`$BIN/set_routes`
