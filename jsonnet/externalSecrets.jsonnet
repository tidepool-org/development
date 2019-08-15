local helpers = import 'helpers.jsonnet';

local Helmrelease(config, group) = helpers.helmrelease(config, group) {
  spec+: {
    chart: {
      git: 'git@github.com:godaddy/kubernetes-external-secrets',
      path: 'charts/kubernetes-external-secrets',
      ref: 'master',
    },
  },
};

function(config) (
  local group = config.groups.externalSecrets { name: 'externalSecrets' };
  if group.enabled then {
    Helmrelease: if group.helmrelease.create then Helmrelease(config, group),
    Namespace: if group.namespace.create then helpers.namespace(config, group),
  }
)
