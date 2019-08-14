local helpers = import 'helpers.jsonnet';

local Helmrelease(config, group) =
  helpers.helmrelease(config, group) {
    local datadog = group,
    spec+: {
      chart: {
        repository: 'https://kubernetes-charts.storage.googleapis.com/',
        name: 'datadog',
        version: '1.32.2',
      },
      values+: {
        kubeStateMetrics: {
          enabled: config.groups.kubeStateMetrics.helmrelease.create,
        },
        datadog: {
          apiKeyExistingSecret: datadog.secret.name,
          appKeyExistingSecret: datadog.secret.name,
          tokenExistingSecret: datadog.secret.name,
          clusterName: config.cluster.eks.name,
          logLevel: config.cluster.logLevel,
        },
        clusterAgent: {
          enabled: true,
          metricsProvider: {
            enabled: true,  // XXX
          },
        },
      },
    },
  };

function(config) {
  local group = config.groups.datadog { name: 'datadog' },
  Helmrelease: if group.helmrelease.create then Helmrelease(config, group),
  Secret: if group.secret.create then helpers.secret(config, group),
  Namespace: if group.namespace.create then helpers.namespace(config, group),
}
