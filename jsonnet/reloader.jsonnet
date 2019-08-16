local helpers = import 'helpers.jsonnet';

local Helmrelease(config, group) = helpers.helmrelease(config, group) {
  spec+: {
    chart: {
      repository: 'https://stakater.github.io/stakater-charts/',
      name: 'reloader',
      version: 'v0.0.38',
    }
  },
};

function(config) (
  local group = config.groups.reloader { name: 'reloader' };
  if group.enabled then {
    Helmrelease: if group.helmrelease.create then Helmrelease(config, group),
    Namespace: if group.namespace.create then helpers.namespace(config, group),
  }
)
