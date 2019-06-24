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

#### Create cluster directory
```
BIN="dev-ops/bin"
cd clusters
mkdir $CLUSTER_NAME
cd $CLUSTER_NAME
```

#### Create cluster configuration
```
echo <<! >config.yaml
apiVersion: eksctl.io/v1alpha5
kind: ClusterConfig

metadata:
  name: qae
  region: us-west-2
  version: "1.13"

nodeGroups:
  - name: ng-1
    instanceType: m5.large
    desiredCapacity: 3
    ssh:
      publicKeyPath:  ~/.ssh/aws-tidepool-derrickburns.pub
    iam:
      withAddonPolicies:
        certManager: true
    labels:
      kiam-server: "false"
  - name: ng-kiam
    instanceType: t3.medium
    desiredCapacity: 1
    ssh:
      publicKeyPath:  ~/.ssh/aws-tidepool-derrickburns.pub
    labels: 
      kiam-server: "true"
    taints:
      kiam-server: "false:NoExecute"
!
```

#### This will take about 10-15 minutes
`$BIN/create_cluster`

#### Add NodeInstanceRole to kiam-server role as Trusted Relationship

#### Add Peering relationship with Atlas


#### install Weave flux (from within the cluster subdirectory)
`$BIN/install_weave`

#### set DNS routes in the manifest and upload that to Git.
`$BIN/set_routes2 $CLUSTER_NAME`
