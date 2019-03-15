## Creating Your Own Private Remote K8S Cluster
If you have access to AWS, you can create your own managed Kubernetes cluster using [Amazon Elastic Container Service for Kubernetes (Amazon EKS)](https://aws.amazon.com/eks/). 

For convenience, our partners at WeaveWorks have created [eksctl](https://eksctl.io/), a terrific tool to create and manage an EKS managed Kubernetres cluster.

#### Install the `eksctl` client

```
brew tap weaveworks/tap
brew install weaveworks/tap/eksctl
```

#### Create Your EKS Cluster
```
eksctl create cluster --auto-kubeconfig --region=us-west-2 --nodes=3
```
This will create a cluster with a generated name and will create a new `KUBECONFIG` file for you.

Save the cluster name in an environment variable for later. Here is a script that uses `jq` to extract the name from eksctl:
```
export CLUSTER_NAME=$(eksctl get cluster --region=us-west-2 -o json | jq ".[0].name" | sed -e "s/\"//g")
```
Save the KUBECONFIG file name as well:
```
export KUBECONFIG="~/.kube/eksctl/clusters/${CLUSTER_NAME}"
```
With `eksctl` you may also adjust the cluster resources as needed.

#### Authenticate with AWS IAM Credentials
You may use your Amazon IAM credentials to authenticate to a Kubernetes cluster using [aws-iam-authenticator](https://docs.aws.amazon.com/eks/latest/userguide/install-aws-iam-authenticator.html).
```
brew install aws-iam-authenticator
```

#### Scale Your Nodegroup	
Virtual machines in Kubernetes that run your services are called nodes. They are organized into node groups that you can scale up or down in size:
```
export NODE_GROUP=$(eksctl get nodegroup --region=us-west-2 --cluster ${CLUSTER_NAME} -o json| jq '.[0].Name' | sed -e 's/"//g')

eksctl scale nodegroup --region=us-west-2 --cluster ${CLUSTER_NAME} --nodes=4 ${NODE_GROUP}
```
#### Delete Your Cluster
When you have no more use for you EKS cluster, you may delete it from Amazon EKS:
```
eksctl delete cluster --name=$(CLUSTER_NAME)
```
These are just a few examples of what you do with `eksctl`.

As an unmanaged alternative to `eksctl`, you may use [kops](https://github.com/kubernetes/kops) to create your own Kubernetes cluster directly on Amazon EC2. This avoids the management fee of Amazon EKS, but places responsibility on you for maintaining the control plan of your Kubernetes cluster.

