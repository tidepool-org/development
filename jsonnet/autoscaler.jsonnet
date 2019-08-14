local helpers = import 'helpers.jsonnet';

local Helmrelease(config, service) = helpers.helmrelease(config,  service) {
  spec+: {
    chart: {
      repository: 'https://kubernetes-charts.storage.googleapis.com/',
      name: 'cluster-autoscaler',
      version: '0.14.2',
    },
    values+: {
      rbac: {
        create: true,
      },
      autoDiscovery: {
        clusterName: config.cluster.eks.name,
      },
      awsRegion: config.cluster.eks.region,
      serviceMonitor: 'enabled',
      sslCertHostPath: '/etc/ssl/certs/ca-bundle.crt',
      extraArgs: {
        v: 4,
        stderrthreshold: 'info',
        logtostderr: true,
        'skip-nodes-with-local-storage': false,
      },
      podAnnotations: helpers.roleAnnotation(config, service.name),
    },
  },
};

function(config) {
  local service = config.services.autoscaler { name: 'autoscaler' },
  Helmrelease: if service.helmrelease.create then Helmrelease(config, service),
  Namespace: if service.namespace.create then helpers.namespace(config, service),
}
