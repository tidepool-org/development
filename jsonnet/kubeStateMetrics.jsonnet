local helpers = import 'helpers.jsonnet';

local Helmrelease(config, group) = helpers.helmrelease(config, group) {
  spec+: {
    values+: {
      hostNetwork: {
        enabled: true,
      },
    },
  },
};

function(config) (
  local group = config.groups.kubeStateMetrics { name: 'kubeStateMetrics' };
  if group.enabled then {
    Helmrelease: if group.helmrelease.create then Helmrelease(config, group),
  }
)
