local helpers = import 'helpers.jsonnet';

local Helmrelease(config, group) =
  helpers.helmrelease(config, group) {
    spec+: {
      values+: {
        rbac: {
          create: true,
        },
        sumologic: {
          collectorUrlExistingSecret: group.secret.name,
        },
        readFromHead: false,
        sourceCategoryPrefix: config.cluster.name,
      },
    },
  };

function(config) (
  local group = config.groups.sumologicFluentd;
  if group.enabled then {
    Helmrelease: if group.helmrelease.create then Helmrelease(config, group),
    Secret: if group.secret.create then helpers.secret(config, group),
    Namespace: if group.namespace.create then helpers.namespace(config, group),
  }
)
