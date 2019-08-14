local helpers = import 'helpers.jsonnet';

local Helmrelease(config, service) = helpers.helmrelease(config, 'kiam', service) {
  spec+: {
    chart: {
      repository: 'https://kubernetes-charts.storage.googleapis.com/',
      name: 'kiam',
      version: '2.3.0',
    },
  },
};

function(config) {
  local service = config.services.sumologic,
  KiamHelmrelease: if service.helmrelease.create then Helmrelease(config, service),
  KiamNamespace: if service.namespace.create then helpers.namespace(config, 'kiam', service),
}
