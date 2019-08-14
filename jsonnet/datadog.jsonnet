local helpers = import 'helpers.jsonnet';

local Helmrelease(config, service) =
  helpers.helmrelease(config, service) {
    local datadog = service,
    spec+: {
      chart: {
        repository: 'https://kubernetes-charts.storage.googleapis.com/',
        name: 'datadog',
        version: '1.32.2',
      },
      values+: {
        kubeStateMetrics: {
          enabled: config.services.kubeStateMetrics.helmrelease.create,
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
  local service = config.services.datadog { name: 'datadog' },
  Helmrelease: if service.helmrelease.create then Helmrelease(config, service),
  Secret: if service.secret.create then helpers.secret(config, service),
  Namespace: if service.namespace.create then helpers.namespace(config, service),
}
