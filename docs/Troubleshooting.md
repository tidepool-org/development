# Troubleshooting

1. <a name="confirm"></a>I just made a change to a Tidepool service. How do I confirm that it is running in my cluster?

    Open up `k9s` and navigate to the namespace of your service. Use `:ns<Enter>` to see the list of available namespaces.  Use the cursor to select the correct namespace.  Click on that row. Now, list the running pods in the service with ":po<Enter>".

    Do you see your service listed in the namespace?  If not, did you select the proper namespace? If not, go back to the previous paragraph.

    If you selected the proper namespace, do you see your service listed?  If so, then use the arrow keys to scroll down to `Containers:{service}:image`. You will see a docker image name of the form:

    ```
    tidepool/{service}:{branch}-{sha}
    ```

     Is that the proper image? The sha should match the commit id of your change. The branch should match the branch that you changed.

    Finally, what is the value of `Containers:{service}:State`? Is it `Running`?  If so, then your service is deployed and running in the cluster.

1. <a name="helmchart"></a>I just made a change to the Tidepool helm chart.  I do not see the new manifests in the cluster.  What do I do?

    - [ ] Is flux running? (Do you see a steady stream of log messages?)
        - [ ] No: Restart flux
        - [ ] Yes:  Is flux helm operator running? (Do you see a steady stream of log messages?) Wait to see it attempt to update thtidepool helm chart.
            - [ ] No: Restart the flux helm operator
            - [ ] Yes: Is there an error in the logs?
                - [ ] Yes: Is there syntax error in a manifest file?
                    - [ ] Yes: Fix manifest file
                    - [ ] Does the log indicate that the release must purged?
                        - [ ] Yes: Using `helm delete {release} --purge`.
                        - [ ] No: Hmmmm.
                - [ ] No: Are there any pods in `Pending` state?
                    - [ ] Yes: See [scheduling issues](#scheduling)
                    - [ ] No: Is your image tag reflected in the Git config repo
                        - [ ] No: Confirm connectivity between Kubernetes anyou Git config repo.
                        - [ ] Yes:

1. <a name="service"></a>The branch is correct and the service is running, but the sha is different. Why isn't my change deployed?

    - [ ] Does the selector used in the helmrelease file match your change? 
    - [ ] No: Change the selector.
    - [ ] Yes: Is your change the latest change that matches the selector?
        - [ ] No: Update selector or rebuild image
        - [ ] Yes: Is your image in Docker Hub?  
            - [ ] No: Did the CI system (Travis) attempt a build of the service artifacts? 
                - [ ] Yes: Did the CI build fail?
                    - [ ] Yes: fix the build.
                    - [ ] No: Did the Docker image get built?
                        - [ ] Yes: Did the CI attempt to push the image to Docker ub
                            - [ ] Yes: Where there any error messages.
                                - [ ] Yes: address errors
                                - [ ] No: Presume intermittent communication issue with Docker Hub. Rerun the build. 
                        - [ ] No: Check the CI script for errors.
                - [ ] No: Did you fail to to push your changes to GitHub?
                    - [ ] Yes: Push the changes to GitHub.
                    - [ ] No: Is the CI system backlogged?
                        - [ ] Yes: Wait
                        - [ ] No: Does the GitHook to CI system work?
                            - [ ] Yes: Rerun build job manually.
            - [ ] Yes: see [helmchart issues](#helmchart)
 

1. <a name="node"></a>I see an unhealthy worker node.  What do I do?
   - Use `eksctl` to drain pods from the node.
   - Delete the unhealthy node in Kubernetes using `kubectl delete node`
   - Delete the EC2 node using AWS commands
   - Wait 5 minutes for the autoscaler to create a new node.
  
1. <a name="k8sversion"></a>There is a new version of Kubernetes available on AWS EKS. I want to update. What do I do?
   - Use `eksctl` to upgrade 

1. <a name="ami"></a>There is a new AMI available for my worker nodes with security fixes. I want to update. What do I do?
   - Use `eksctl` to create a new node group.
   - Use `eksctl` to migrate service to the new node group.

1. <a name="scheduling"></a>I see pods in the `Pending` state.  What do I do?
  Your cluster autoscaler may need to increase the number of nodes in your cluster.  This can take up to 5 minutes. Does waiting 5 minutes resolve the pending pods?

    - [ ] Is the cluster autoscaler running?
        - [ ] No: Restart cluster autoscaler
        - [ ] Yes: Is your node group at max capacity?
            - [ ] Yes: Increase autoscaling group limit.
            - [ ] No: Is your metrics service running?
                - [ ] Yes: Is your autoscaler receiving metrics from the metrics server?
                   - [ ] Yes: Are your nodes healthy?
                       - [ ] No: Create a new node
                   - [ ] No: Investigate connection bewteen metrics server and autoscaler.
                - [ ] No: Start metrics server

1. I received an alert that we are at nearing capacity for our storage. What do I do?

1. Response time appear to be growing. What do I do?

    Confirm that [autoscaling](#scheduling) is working properly. If so, gather traces.

1. My service is in a CrashLoopBackoff.  What do I do?
 
    This means that the service is crashing after it starts. Look at the pod logs by using the 'kubectl logs -n {namespace} {pod-name}` command.

1. My service is in the `Init` state. What does that mean?

   This means that it is waiting for another service to start.  At present, the only service that we wait for is `shoreline`.

1. I cannot connect to my AtlasDB or Amazon DocumentDB service.  What do I do?

    Confirm that your mongo connections parameters are correct and, if you need a mongo password, that the password is in a secret.  

    If you are given a Mongo SRV record, get the names of the hosts.

    Open a shell on your service.  Confirm that you can reach the port by running `nc -zv {hostname} 27017`.

    If you cannot reach the hostname, look up the host name using `nslookup {hostname}`.  If you cannot retrieve the host name, confirm that your have the proper peering relationship AND that the routing tables allow routing to your host.

1. I cannot connect to mongodb running on my local laptop. What do I do?

    To reach your local mongo, your local machine needs a DNS name other than localhost.  Add one to `/etc/hosts` and use that name as your mongo host name.

1. I created an environment named `foo`. How do I make `foo` discoverable by DNS?

   Add the DNS name to the annotations in the Gloo api-gateway. Then, check in the change to GitHub.  In a few minutes, the DNS name will be advertised.

1. I need to generate a new TLS certificate. How do I do that?

   Create a certificate request in the proper namespace. The cert-manager will then use the ACME protocol to create, store, and renew the certificate automatically.

1. My service cannot access AWS resources.  How can I give my services permission to do so?

   1. Create role with the desired permissions.
   1. Allow the `kiam-server` role permission to assume your new role using a [trust relationship](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_manage_modify.html).
   1. Add an annotation to your service with the name of the role, e.g.
      ```
      kind: Pod
      metadata:
        name: foo
        namespace: iam-example
        annotations:
          iam.amazonaws.com/role: reportingdb-reader
      ```
   1. Add an annotation (a regex) to the namespace that captures the name of the role that you added, e.g. 

      ```
      kind: Namespace
      metadata:
        name: iam-example
        annotations:
          iam.amazonaws.com/permitted: ".*"
      ```

1. IAM is not working for any service on my node. What do I do?

   This likely means that the `kiam-server` IAM role does not allow the node instance role (associated with the node group) to assume its role. Add the "Trust Permissions."
