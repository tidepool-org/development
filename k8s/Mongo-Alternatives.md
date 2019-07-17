## Advanced: Using your own Mongo Instance
If you already have an instance of Mongo running 3.6, then you may use it as long as it can be discovered by DNS.

#### Create a DNS Name for a Local Mongo Instance
If you have an instance of Mongo 3.6 running on your local machine, but outside of Kubernetes, then you must create a DNS name for it (other than localhost). To do so, create a local DNS name by editing your `/etc/hosts` file. 

Then, when you install the Tidepool helm chart, set the mongo parameters accordingly, using the host name that you placed
in your `/etc/hosts` file.
