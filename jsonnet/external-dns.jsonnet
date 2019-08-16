local helpers = import 'helpers.jsonnet';

local Helmrelease(config, group) = helpers.helmrelease(config, group) {
  spec+: {
    values+: {
      rbac: {
        create: true,
      },
      logLevel: config.cluster.logLevel,
      aws: {
        region: config.cluster.eks.region,
        zoneType: 'public',
      },
      metrics: {
        enabled: config.cluster.metrics.enabled
      },
      txtOwnerId: config.cluster.name,
    },
  },
};

function(config) (
  local group = config.groups.externalDNS { name: 'external-dns' };
  if group.enabled then {
    Helmrelease: if group.helmrelease.create then Helmrelease(config, group),
    Namespace: if group.namespace.create then helpers.namespace(config, group),
  }
)
