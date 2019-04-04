This directory stores the configuration for several separate instances of the Tidepool services.  Each instance is defined in a subdirectory of the `namespaced` directory.

### Tools
* Install AWS CLI, `aws`.
```
brew install awscli
```
* Install the kubernetes CLI, `kubectl`.
```
brew install kubernetes-cli
```
* Install the kubernetes log tailer, `kail`
```
brew tap boz/repo && brew install boz/repo/kail
```
* Install the curse-based kubernetes inspector, `k9s`.
```
brew tap derailed/k9s && brew install k9s
```
* Install the aws iam authenticator, `aws-iam-authenticator`.
```
brew install aws-iam-authenticator
```

### Authentication
In order to authenticate yourself to the Kubernetes cluster running in Amazon EKS
* provide your AWS credentials in the normal way
  * we are in the `us-west-2` region
* install the [KUBECONFIG](https://github.com/tidepool-org/dev-ops/blob/qa/k8s/amazing-sculpture-1549406110.yaml) file into `~/.kube/config` if you don't already have a file there. Change `you` to your AWS iam name, e.g. `derrick-cli`.
```
apiVersion: v1
clusters:
- cluster:
    certificate-authority-data: LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCk1JSUN5RENDQWJDZ0F3SUJBZ0lCQURBTkJna3Foa2lHOXcwQkFRc0ZBREFWTVJNd0VRWURWUVFERXdwcmRXSmwKY201bGRHVnpNQjRYRFRFNU1ESXdOVEl5TkRJek5Gb1hEVEk1TURJd01qSXlOREl6TkZvd0ZURVRNQkVHQTFVRQpBeE1LYTNWaVpYSnVaWFJsY3pDQ0FTSXdEUVlKS29aSWh2Y05BUUVCQlFBRGdnRVBBRENDQVFvQ2dnRUJBTFRRCkhCSW40V2FycEFNUTlTdWlrNGFrY0h1MnJwRnlOa1JZVHhDaEZLbmh3OUNHSGpHQkhPVXhHU0ZUYlNndG0vWTQKQUFMckJOS1JXRUx4QTZOOXJSaVF1V0J1TlNCUitZU2tqc3EvaXdUMzB0RnB4RjdlVFJDSXJFa0ZLcnFOMXJCNwowU1BxcEZRZS94ZHo1eHBoSGsxOHBrakhmYUgyZ2xob2hKR1NXNCtmcFEwUlJhQ0wwNjg0MytKYnJTTnVGUG0zCnRidENLVFo4aUFjZm1YcUYzek11bzlsRHEwZTJ1ai92UEJxcTlsMVROTjRBUHpBM3V6WkVZVy9yRzdSczlXOGsKTk0zdTRmNU5tWDduSTlwbGFNenlrWW5CcU9DalJESzRGVU9QRHBxZjAyVjVOZWFtcjdrSk9MWDdJekhXc0RZUgorWkh3SnI0VUNGNEVFT3V0ZFA4Q0F3RUFBYU1qTUNFd0RnWURWUjBQQVFIL0JBUURBZ0trTUE4R0ExVWRFd0VCCi93UUZNQU1CQWY4d0RRWUpLb1pJaHZjTkFRRUxCUUFEZ2dFQkFERWRNdHFnVnFTdlVGTk9jQ2lpMTRMU3FOenMKZzNKeWJ6aU1Lb1VuS1JJeGxYbUpsb0k3MFg1WDdlYlVZalM5Vi9iYUwwdjNUVlptZzM3UVM5VEpRbWN1Y2tGNwp0VEdMdXNXaGY1Vm5Qc3ErbTVpcG0vSmt2OWkrZ1NFVnZsL0Z2eExBUGZsRzR6TDRjR0lRRXY3d20wUy9GZXQyCkU0N2NSRkNOZitSM2dQYTBRNHRVd1NqZDdtc1RkWWdxRVBMWks1OFlPblM1OVE3QjZWNEVpZ2xPVzVwWVlzZnIKd0dkNXY5RFJ1TXJUbVdBaEQ1M2tlaTZKUmVDOUdkeWF4aHNCZld1TnNOR0tBaWRqY21WL2xidVord1RTSjBUTQpkYmtXcGl1RG9SbDhhZVBUUWVlZjBrZTJUU1BjcTFHbFQ4RUIvV2prSVl2WWJzK0xoaDlkenY2YXk5QT0KLS0tLS1FTkQgQ0VSVElGSUNBVEUtLS0tLQo=
    server: https://9290AF532283F930D0B7C6ECB9D47DB6.sk1.us-west-2.eks.amazonaws.com
  name: amazing-sculpture-1549406110.us-west-2.eksctl.io
contexts:
- context:
    cluster: amazing-sculpture-1549406110.us-west-2.eksctl.io
    user: you@amazing-sculpture-1549406110.us-west-2.eksctl.io
  name: you@amazing-sculpture-1549406110.us-west-2.eksctl.io
current-context: you@amazing-sculpture-1549406110.us-west-2.eksctl.io
kind: Config
preferences: {}
users:
- name: you@amazing-sculpture-1549406110.us-west-2.eksctl.io
  user:
    exec:
      apiVersion: client.authentication.k8s.io/v1alpha1
      args:
      - token
      - -i
      - amazing-sculpture-1549406110
      command: aws-iam-authenticator
      env: null
```
* set and export the `KUBECONFIG` variable to point to the above file
```
export KUBECONFIG=~/.kube/config
```

You know it worked if you can do:
```
kubectl get pods
```

### GitOps
To make changes to a Tidepool instance, simply change the manifests in the subdirectory of the `namespaced` directory.  N.B. The directory
structure is *immaterial* to how the resources are utilized in Kubernetes.  To associate a manifest with a particular Tidepool instance, you *must*
set the namespace in the manifest.  This is how Kubernetes knows which Tidepool instance you intend to affect. 

### Mongo Storage
Each Tidepool instance has a separate instances of Mongo.  The storage is backed by a Kubernetes Persisent Volume.  Should the Mongo instance be restarted, the volume will continue to exist.

### Kubernetes Namespaces
Each Tidepool instance lives in separate Kubernetes namespace. 

### API Gateway - Shared
The Tidepool instances share a single API Gateway that performs host-based routing to separate the traffic. 

### Weave - Shared
Each Tidepool instance requires the [Weave Flux](https://medium.com/@m.k.joerg/gitops-weave-flux-in-detail-77ce36945646) service to be running in the cluster.

### Usage and Configuration Notes

##### QA1
QA1 is used by Derrick for bringing up the overall K8s infrastructure, including shared services like API gateway, Mongo storage, and eventually a service mesh such as Istio. 
##### QA2
##### QA3
##### QA4

