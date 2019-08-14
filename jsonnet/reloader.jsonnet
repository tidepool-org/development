local helpers = import 'helpers.jsonnet';

local Helmrelease(config, group) = helpers.helmrelease(config, group) {
  spec+: {
    chart: {
      git: 'git@github.com:stakater/Reloader',
      path: 'deployments/kubernetes/chart/reloader',
      ref: 'master',
    },
  },
};

function(config) {
  local group = config.groups.reloader { name: 'reloader' },
  Helmrelease: if group.helmrelease.create then Helmrelease(config, group),
  Namespace: if group.namespace.create then helpers.namespace(config, group),
}
