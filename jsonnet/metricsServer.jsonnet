local helpers = import 'helpers.jsonnet';

local Helmrelease(config, service) = helpers.helmrelease(config, 'metricsServer', service) {
  spec+: {
    chart: {
      repository: 'https://kubernetes-charts.storage.googleapis.com/',
      name: 'metrics-server',
      version: '2.8.2',
    },
  },
};

function(config) {
  local service = config.services.metricsServer,
  MetricsServerHelmrelease: if service.helmrelease.create then Helmrelease(config, service),
  MetricsServerNamespace: if service.namespace.create then helpers.namespace(config, 'metricsServer', service),
}
