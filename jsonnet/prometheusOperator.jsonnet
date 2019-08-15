local helpers = import 'helpers.jsonnet';

local Helmrelease(config, group) = helpers.helmrelease(config, group) {
  local thanos = config.groups.thanos,

  spec+: {
    chart: {
      repository: 'https://kubernetes-charts.storage.googleapis.com/',
      name: 'prometheus-operator',
      version: '5.13.0',
    },
    values+: {
      prometheus: {
        prometheusSpec: {
          replicas: group.helmrelease.data.prometheus.replicaCount,  // work in High-Availability mode
          retention: group.helmrelease.data.prometheus.retention,  // we only need a few hours of retention, since the rest is uploaded to blob
          image: {
            tag: 'v2.8.0',  // use a specific version of Prometheus
          },
          externalLabels: {  // a cool way to add default labels to all metrics
            geo: 'us',
            region: config.cluster.eks.region,
          },
          groupMonitorNamespaceSelector: {  // allows the operator to find target config from multiple namespaces
            any: true,
          },
          thanos: {  // add Thanos Sidecar
            tag: thanos.deployment.tag,  // a specific version of Thanos
            objectStorageConfig: {  // blob storage configuration to upload metrics
              key: 'thanos.yaml',
              name: thanos.secret.name,
            },
          },
        },
      },
      grafana: {  // (optional) we don't need Grafana in all clusters
        enabled: false,
      },
    },
  },
};

function(config) (
  local group = config.groups.prometheusOperator { name: 'prometheusOperator' };
  if group.enabled then {
    Helmrelease: if group.helmrelease.create then Helmrelease(config, group),
    Namespace: if group.namespace.create then helpers.namespace(config, group),
  }
)
