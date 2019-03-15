
### Running Tidepool on Kubernetes
Tidepool can be run on Kubernetes. Here are the instructions on: 
* [How to Install Client Tools](#How-to-Install-Client-Tools)
* [How to Create A Local Kubernetes Cluster](#How-to-Create-A-Kubernetes-Cluster)
* [How to Bootstrap Your Cluster](#How-to-Bootstrap-Your-Cluster)
* [How to Install the Tidepool Services](#How-to-Install-the-Tidepool-Services)
* [How to Access the Tidepool Services](#How-to-Access-the-Tidepool-Services)
* [How to Inspect Your Cluster](#How-to-Inspect-Your-Cluster)

### How to Install Client Tools

There are a number of useful client tools for interacting with a Kubernetes cluster.  These instructions assume that you are on MacOSX.

Get the client tools and install them onto your local machine. We recommend that you use the `brew` tool for this on a Mac.

#### Install [kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl/), the Kubernetes CLI tool

This tool will allow you to manipulate your Kubernetes cluster.
```
brew install kubernetes-cli
```
#### Install [kail](https://github.com/boz/kail), the Kubernetes log tailer (Recommended) 

This tool will allow you to aggregate log messages from the many sources within Kubernetes.
```
brew tap boz/repo
brew install boz/repo/kail
```

### How to Create A Kubernetes Cluster
You may create a Kubernetes cluster on your local machine, on machines in your data center ("on prem"), or on a cloud service.  In each case, there are several ways to do so.  

Here we provide instructions for creating a single node "cluster" on your local machine.  

There are several ways to run Kubernetes on your local machine ([docker desktop](https://rominirani.com/tutorial-getting-started-with-kubernetes-with-docker-on-mac-7f58467203fd), [k3s](https://k3s.io/), [minikube](https://kubernetes.io/docs/setup/minikube/), [kind](https://github.com/kubernetes-sigs/kind), etc.) and several [opinions](https://medium.com/containers-101/local-kubernetes-for-mac-minikube-vs-docker-desktop-f2789b3cad3a) on which is best.  Any one will probably do. 

However, we choose to document `minikube` because it offers the opportunity to select a particular version of Kubernetes and it runs on all manner of desktops, including MacOSX, Linux, and Windows.

Install [minikube](https://github.com/kubernetes/minikube) (see [this excellent tutorial](https://codefresh.io/kubernetes-tutorial/local-kubernetes-mac-minikube-vs-docker-desktop/))
```
brew cask install minikube
```
If you are using a Mac, you can install the hyperkit driver vm:

```
brew install docker-machine-driver-hyperkit
sudo chown root:wheel /usr/local/opt/docker-machine-driver-hyperkit/bin/docker-machine-driver-hyperkit
sudo chmod u+s /usr/local/opt/docker-machine-driver-hyperkit/bin/docker-machine-driver-hyperkit
minikube config set vm-driver hyperkit
```
#### Configure minikube
(to use the same version of K8s that Tidepool uses)
```
minikube config set kubernetes-version v1.11.5
minikube config set memory 8192
minikube config set cpus 4
```
#### Start minikube and modify networking 
```
minikube start --extra-config=apiserver.authorization-mode=RBAC
minikube ssh -- sudo ip link set docker0 promisc on
```
#### Configure CLI tools to talk to your local cluster. 

In **each and every window** that you will use the Docker cli, you must set environment variables to use the Docker daemon in the minikube VM:
```
eval $(minikube docker-env)
```
#### Stop your cluster
Kubernetes can be a heavy resource consumer.  So, you may want to (non-destructively) stop the virtual machine running your cluster when you are not using it.  You may restart it later with the `minikube start `command above.
```
minikube stop
```

### How to Bootstrap Your Cluster

The Tidepool backend requires a small set of basic services to run within your Kubernetes cluster that you must install manually. 

#### Install Helm Service (Tiller)

The Tidepool Kubernetes manifests are created and installed using the [helm](https://helm.sh/) package manager.  To run the Helm package manager, you must install the server-side component of Helm called Tiller: 
```
kubectl -n kube-system create sa tiller
kubectl create clusterrolebinding tiller-cluster-rule --clusterrole=cluster-admin --serviceaccount=kube-system:tiller
helm init --skip-refresh --upgrade --service-account tiller
```

#### Install Kubernetes Dashboard
To see what is running in your cluster, we use the [Kubernetes dashboard](http://localhost:8001/api/v1/namespaces/kube-system/services/https:kubernetes-dashboard:/proxy/#!/login) which provides safe, authenticated access to the cluster:
```
kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/master/aio/deploy/recommended/kubernetes-dashboard.yaml
```

#### Accessing Your Kubernetes dashboard

Run ```kubectl proxy``` to forward the connection.

A token is needed to access the k8s dashboard, retrieve the token as follows:

```
SECRET_NAME=$(kubectl get serviceaccount default -n kube-system -o jsonpath='{.secrets[].name}')

kubectl get secret ${SECRET_NAME} -o jsonpath='{.data.token}' -n kube-system | base64 -D
```

Open the [dashboard](http://localhost:8001/api/v1/namespaces/kube-system/services/https:kubernetes-dashboard:/proxy/#!/login) and provide the token (if requested).


### How to Install the Tidepool Services
We install the Tidepool services using the [Helm package manager](https://helm.sh/).

You have a choice in how you use helm. You may install the Tidepool services into your cluster manually using the helm CLI or you may use another tool called Weave Flux to install the Tidepool services using helm on your behalf.  

With the manual approach, if you make a configuration, e.g. change the Docker image used for a given service, then you would use the helm CLI to update the cluster.

With the automated approach, you would simply edit a file on GitHub or push a new image to Docker Hub, and Weave Flux would notice the change and update your cluster using helm on your behalf.


#### Clone the Tidepool Repo
So, let use start off by cloning the Tidepool repo with the helm chart. 

```
export CONFIG_REPO="git@github.com:${YOUR-GITHUB-ID}/development.git"
export YOUR_BRANCH_NAME=my_config
git clone git@github.com:tidepool-org/development.git
git remote add origin ${CONFIG_REPO}
cd development
export REPO_DIR=$(pwd)
git checkout k8s
git checkout -b ${YOUR_BRANCH_NAME}
```
Now you have your own clone of the repo and a branch to work in. 

#### Manual Update

To perform manual updates using Helm, you will need the Helm CLI tool. 

#### Install Helm Client
To manually install the Tidepool services into your Kubernetes cluster, you use the Helm client.  This tool will allow  you to install packages on your Kubernetes cluster.
```
brew install kubernetes-helm
```
#### Install Tidepool Helm Chart
Helm packages are called `charts`.  The [Helm chart for Tidepool](https://github.com/tidepool-org/development/tree/k8s/k8s/charts/tidepool) is stored in the public GitHub development repo in the _k8s_ branch at present. When you install a Helm package into a cluster, the installation itself is given a name, called the *release name*. 

You may install the Tidepool services directly into the default namespace of your cluster with this Helm command, where `RELEASE_NAME` is a name of your choosing:

```
helm install ${REPO_DIR}/k8s/charts/tidepool --name ${RELEASE_NAME}
```
#### Changing Docker Images for Tidepool Services
The Kubernetes Deployment manifests make reference to the specific Docker images used for the Tidepool services. With Helm, these manifests are templated to allow for variable substitution and other manipulations. 

In our Tidepool Helm [template files](https://github.com/tidepool-org/development/tree/k8s/k8s/charts/tidepool/templates), we have variable for each Docker image.  The default values are provided in the [values.yaml](https://github.com/tidepool-org/development/blob/k8s/k8s/charts/tidepool/values.yaml). file. 

To change the Docker images while the cluster is running, first create a local file (`values-override.yaml`) with the image name and tags to change.  Then, upgrade your helm release with the   `helm upgrade` command and provide a set of new values in a local file:

```
helm upgrade ${RELEASE_NAME} ${REPO_DIR}/k8s/charts/tidepool -f values-override.yaml
```

#### GitOps

As an alternative to manually running Helm to upgrade your Tidepool services on each change of a Docker image used, you may use the [Weave Flux](https://www.weave.works/oss/flux/) product to watch for new images on Docker Hub.  

Weave Flux does this by reference to a GitHub repo that you provide that stores a copy of the Helm release configurations and any other non-Helm Kubernetes manifest files that you want to run on your Kubernetes cluster. Let's call this your <code>config</code> repo.

#### Weave Workflow
The workflow is simple.  

First, you install Weave Flux itself into your Kubernetes cluster.  When you install it, you configure Weave Flux with the URL to the GitHub repo with your Helm release configurations and Kubernetes manifests. 

Then, Weave Flux will poll the your GitHub `CONFIG_REPO`. It will compare the contents of the config repo with what it has previously installed in your cluster.  If the two have diverged, it was make them identical by changing the Kubernetes resources in your cluster to match what is in your `CONFIG_REPO`.

Finally, using helm, install the Weave Flux operator into your cluster:

#### Publish Your Config Repo to GitHub
In order to use Weave Flux, you must publish your repo to GitHub:

```
cd ${REPO_DIR}
git push origin ${YOUR_BRANCH_NAME}
```
Then watch how Weave Flux keeps your Kubernetes cluster in sync.

#### Install Weave Flux
Weave Flux runs as a service inside your Kubernetes cluster. You install it with Helm using the Weave Flux Helm chart.

```
helm repo add weaveworks https://weaveworks.github.io/flux

helm install --name flux --set rbac.create=true --set helmOperator.create=true --set git.url=${CONFIG_REPO} --set git.branch=${YOUR_BRANCH_NAME} --set git.pollInterval=1m --set helmOperator.replicaCount=1 weaveworks/flux
```
N.B. Weave flux will install ALL kubernetes manifests that it discovers in the branch of your` CONFIG_REPO`. It will also look for files with valid `HelmRelease` manifest file and install the helm releases according to the files found.

The [HelmRelease manifest file](https://github.com/tidepool-org/development/blob/k8s/k8s/release/backend.yaml) for your Tidepool backend is stored at `${REPO_DIR}/k8s/release/backend.yaml`. To configure Weave Flux to watch for new Docker images posted to Docker Hub, modify that file. See the [Flux documentation](https://github.com/weaveworks/flux) for details.

#### Enable Weave Flux to Update Your GitHub Repo
In order to allow  Flux to install new Docker images, Flux will need write access to your Git repo. You provide that by getting the Flux public key from the Flux server using the Flux client and by adding the key to your Git Repo as a "deploy key". 


#### Install the [Weave Flux Client](https://github.com/weaveworks/flux) 
To retrieve the key, you may use the Flux CLI tool `fluxctl`.
client, the GitOps Kubernetes operator (optional).

This tool will allow you to update the Docker images running in your cluster merely by modifying a GitHub repo.
```
brew install fluxctl
```

#### Retrieve Flux Public Key
The flux client has a command to retrieve the key from the server:
```
fluxctl identity
```
#### Post the Flux Public Key to GitHub
Then, open GitHub, navigate to your fork, go to `Setting > Deploy` keys click on `Add deploy key,` check` Allow write access`, paste the Flux public key and click `Add key`.

### How to Access the Tidepool Services

Once you have installed the Tidepool services in your cluster, they will start and run.  

#### Connect to Blip, the Tidepool Frontend
To access the Tidepool Web portal, you need to forward a local port to the port that provides the Tidepool Web application

```
kubectl port-forward svc/blip 3000:3000 &
```
Open [localhost:3000](localhost:3000)

#### Forward API Requests to API Gateway
At present, you must also forward traffic from the API Gateway to the Tidepool backend.` `This is needed to inform the Tidepool web app where the Tidepool API server is located. The default config is localhost.  In production, this would be replaced with the DNS name of the Api server.  Now, we just manually forward to the internal service. 

(make sure to include the name of your service if you did not use default, e.g. ```mydeploy-amabassador```


```
kubectl port-forward deployment/default-ambassador 8009 &
```
### How to Inspect Your Cluster

There are several ways to inspect what is happening inside your cluster.  Foremost is inspecting the Kubernetes dashboard that you installed above.  From the dashboard, you may inspect the logs of any running Kubernetes.  You may also inspect the logs from the command line.

There are a number of other optional services that you may choose to run in your cluster, including [Istio](https://istio.io/) (service mesh), [Prometheus](https://prometheus.io/) (metrics), [Grafana](https://grafana.com/) (analytics and monitoring), [Kiali](https://www.kiali.io/) (service mesh observability), and Jaeger (distributed tracing).  Each offers its own web interface.  Follow the instructions below to inspect those services.
*   Web Services 
Given private access (`kubectl`) to a Kubernetes cluster, you may look at Kubernetes web services by forwarding the port of a service to a local port.
    *   Ambassador Admin Console in browse
        *   `kubectl port-forward deployment/ambassador 8877 &`
        *   Open [http://localhost:8877/ambassador/v0/diag/](http://localhost:8877/ambassador/v0/diag/)
    *   Kubernetes Dashboard
        *   <code>kubectl proxy</code>
        *   Get token to authenticate
            *   <code>SECRET_NAME=$(kubectl get serviceaccount default -n kube-system -o jsonpath='{.secrets[].name}')</code>
            *   <code>kubectl get secret ${SECRET_NAME} -o jsonpath='{.data.token}' -n kube-system | base64 -D</code>
        *   Open [http://localhost:8001/api/v1/namespaces/kube-system/services/https:kubernetes-dashboard:/proxy/#!/login](http://localhost:8001/api/v1/namespaces/kube-system/services/https:kubernetes-dashboard:/proxy/#!/login)

*   Logs
    *   All services
        *   <code>kail</code>
    *   All services in the default namespace
        *   <code>kail -n default </code>
    *   Tidepool Web
        *   <code>kail --svc blip</code>
    *   Istio (if installed)
        *   <code>kail -n istio-system</code>
    *   Tiller
        *   <code>kail -n kube-system --svc tiller</code>
*   GitOps
    *   Set what version of Tidepool containers are deployed
        *   <code>fluxctl list-controllers</code>
    *   See what images are available to deploy
        *   <code>fluxctl list-images</code>

