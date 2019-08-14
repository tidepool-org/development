local helpers = import 'helpers.jsonnet';

local Helmrelease(config, service) = helpers.helmrelease(config, 'reloader', service) {
  spec+: {
    chart: {
      git: 'git@github.com:stakater/Reloader',
      path: 'deployments/kubernetes/chart/reloader',
      ref: 'master',
    },
  },
};

function(config) {
  local service = config.services.reloader,
  Helmrelease: if service.helmrelease.create then Helmrelease(config, service),
  Namespace: if service.namespace.create then helpers.namespace(config, 'reloader', service),
}
