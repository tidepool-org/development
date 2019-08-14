local helpers = import 'helpers.jsonnet';

local Helmrelease(config, group) = helpers.helmrelease(config, group) {
  spec+: {
    chart: {
      repository: 'https://kubernetes-charts.storage.googleapis.com/',
      name: 'metrics-server',
      version: '2.8.2',
    },
  },
};

function(config) {
  local group = config.groups.metricsServer { name: 'metricsServer' },
  Helmrelease: if group.helmrelease.create then Helmrelease(config, group),
  Namespace: if group.namespace.create then helpers.namespace(config, group),
}
