local helpers = import 'helpers.jsonnet';

local Helmrelease(config, service) = helpers.helmrelease(config, 'kubeStateMetrics', service) {
  spec+: {
    chart: {
      repository: 'https://kubernetes-charts.storage.googleapis.com/',
      name: 'kube-state-metrics',
      version: '2.2.1',
    },
    values+: {
      hostNetwork: {
        enabled: true,
      },
    },
  },
};

function(config) {
  local service = config.services.kubeStateMetrics,
  KubeStateMetricsHelmrelease: if service.helmrelease.create then Helmrelease(config, service),
}
