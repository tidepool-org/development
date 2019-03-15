## Visualizing Optional Services
    *   [Service Graph](https://istio.io/docs/tasks/telemetry/servicegraph/) (if installed)
        *   <code>kubectl port-forward -n istio-system svc/servicegraph 8088:8088 &</code>
        *   Open [http://localhost:8088/force/forcegraph.html](http://localhost:8088/force/forcegraph.html) 
    *   [Kiali](https://www.kiali.io/) (if installed)
        *   <code>kubectl port-forward -n istio-system svc/kiali 20001:20001 &</code>
        *   Open [http://localhost:20001/kiali](http://localhost:20001/kiali)
    *   [Prometheus](https://istio.io/docs/tasks/telemetry/querying-metrics/) (if installed)
        *   <code>kubectl port-forward -n istio-system svc/prometheus 9090:9090 &</code>
        *   Open [http://localhost:9090/graph](http://localhost:9090/graph)
    *   [Jaeger](https://istio.io/docs/tasks/telemetry/distributed-tracing/)  (if installed)
        *   <code>kubectl port-forward -n istio-system svc/jaeger 16686:16686 &</code>
        *   Open [http://localhost:16686](http://localhost:16686/)