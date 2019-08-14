local helpers = import 'helpers.jsonnet';

local Helmrelease(config, service) = helpers.helmrelease(config, 'sumologic', service) {
  spec+: {
    chart: {
      repository: 'https://kubernetes-charts.storage.googleapis.com/',
      name: 'sumologic-fluentd',
      version: '1.1.0',
    },
  },
};

function(config) {
  local service = config.services.sumologic,
  ReloaderHelmrelease: if service.helmrelease.create then Helmrelease(config, service),
  ReloaderNamespace: if service.namespace.create then helpers.namespace(config, 'sumologic', service),
}
