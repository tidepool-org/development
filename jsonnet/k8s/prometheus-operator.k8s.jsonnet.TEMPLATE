local helpers = import 'helpers.jsonnet';

local Helmrelease(config, group) = helpers.helmrelease(config, group) {
  local thanos = config.groups.thanos,

  spec+: {
    values+: {
      prometheus+: {
        prometheusSpec+: {
          image: {
            tag: 'v2.8.0',  // use a specific version of Prometheus
          },
          externalLabels: {  // a cool way to add default labels to all metrics
            geo: 'us',
            region: config.cluster.eks.region,
          },
          serviceMonitorNamespaceSelector: {  // allows the operator to find target config from multiple namespaces
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
  local group = config.groups.prometheusOperator;
  if group.enabled then {
    Helmrelease: if group.helmrelease.create then Helmrelease(config, group),
    Namespace: if group.namespace.create then helpers.namespace(config, group),
  }
)
