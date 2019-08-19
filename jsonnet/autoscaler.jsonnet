local helpers = import 'helpers.jsonnet';

local Helmrelease(config, group) = helpers.helmrelease(config, group) {
  spec+: {
    values+: {
      rbac: {
        create: true,
      },
      autoDiscovery: {
        clusterName: config.cluster.name,
      },
      awsRegion: config.cluster.eks.region,
      serviceMonitor: {
        enabled: true,
      },
      sslCertHostPath: '/etc/ssl/certs/ca-bundle.crt',
      extraArgs: {
        v: 4,
        stderrthreshold: 'info',
        logtostderr: true,
        'skip-nodes-with-local-storage': false,
      },
    },
  },
};

function(config) (
  local group = config.groups.autoscaler;
  if group.enabled then {
    Helmrelease: if group.helmrelease.create then Helmrelease(config, group),
    Namespace: if group.namespace.create then helpers.namespace(config, group),
  }
)
