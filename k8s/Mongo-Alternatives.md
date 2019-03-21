## Advanced: Using your own Mongo Instance
If you already have an instance of Mongo running 3.2, then you may use it as long as it can be discovered by DNS.

#### Create a DNS Name for a Local Mongo Instance
If you have an instance of Mongo 3.2 running on your local machine, but outside of Kubernetes, then you must create a DNS name for it (other than localhost). To do so, create a local DNS name by editing your `/etc/hosts` file. 

TODO: Confirm that Kubernetes routes DNS lookups through the host DNS!

#### Notify Kuberenetes of your Mongo Service
Once you have a Mongo instance running 3.2 that is accessible via DNS, then you notif Kuberenetes of its availablity as a service named "mongo"
by installing the following Kubernetes [ExternalName](https://kubernetes.io/docs/concepts/services-networking/service/#externalname) Manifest. Simply substitute the URL to your Mongo instance where you see `my.mongo.example.com`. 
```
kind: Service
apiVersion: v1
metadata:
  name: mongo
  namespace: prod
spec:
  type: ExternalName
  externalName: my.mongo.example.com
```
If you place this manifest in a file called `external-mongo.yaml`, then you may install this manifest using `kubectl apply -f external-mongo.yaml`.

