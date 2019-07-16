## How to Debug Your Kubernetes Services

Debugging Kubernetes services can be as easy as debugging services running locally with 
[Tilt](https://tilt.dev/),
[Telepresence](https://www.telepresence.io/discussion/overview) or [Squash](https://squash.solo.io/)

#### Tilt
With Tilt, you can edit your services and kubernetes manifest files locally and Tilt will rebuild and redeploy as needed.

From the developer:

>Tilt is super fast to set up for greenfield projects, but it really shines when your setup requires some “extra love” (and even then it’s still pretty quick!) Any setup, any architecture, no matter how complex. Any engineer can run tilt up to see the app live instantly.

>Tilt watches your filesystem and updates your servers in seconds so you can spend more time getting stuff done and less time watching paint dry. Tilt makes even the most complicated setups feel snappy again — and that’s no easy task.

>Stop playing 20 questions with kubectl each time your app misbehaves. Tilt collects problems from across tools and services into one UI. One place to see build breakages, yaml typos, crash loops, and request exceptions.

#### Telepresence
With Telepresence, you run and debug *one* service locally that *appears to Kubernetes to be running in your Kubernetes cluster*.

From the developer:

>Presence is an open source tool that lets you run a single service locally, while connecting that service to a remote Kubernetes cluster. This lets developers working on multi-service applications to:
>
> * Do fast local development of a single service, even if that service depends on other services in your cluster. Make a change to your service, save, and you can immediately see the new service in action.
>
> * Use any tool installed locally to test/debug/edit your service. For example, you can use a debugger or IDE!
>
> * Make your local development machine operate as if it's part of your Kubernetes cluster. If you've got an application on your machine that you want to run against a service in the cluster -- it's easy to do.

#### Squash
With Squash, all services run in your Kubernetes, but *appear to your debugger to run locally*.

From the developer:

>Squash brings the power of modern debuggers to developers of microservice apps. Squash bridges between the apps running in a Kubernetes environment (without modifying them) and the IDE. Users are free to choose which containers, pods, services or images they are interested in debugging, and are allowed to set breakpoints in their codes, follow values of their variables on the fly, step through the code while jumping between microservices, and change these values during run time.
>
>With Squash, you can:
> * Debug running microservices
> * Debug container in a pod
> * Debug a service
> * Set breakpoints
> * Step through code
> * View and modify values of variables
> …anything you could do with a regular debugger, and more!
