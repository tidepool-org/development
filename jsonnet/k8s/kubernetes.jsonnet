local helpers = import 'helpers.jsonnet';

local groups = [
  import 'autoscaler.k8s.jsonnet.TEMPLATE',
  import 'cert-manager.k8s.jsonnet.TEMPLATE',
  import 'datadog-agent.k8s.jsonnet.TEMPLATE',
  import 'external-dns.k8s.jsonnet.TEMPLATE',
  import 'external-secrets.k8s.jsonnet.TEMPLATE',
  import 'fluxcloud.k8s.jsonnet.TEMPLATE',
  import 'gloo.k8s.jsonnet.TEMPLATE',
  import 'kiam.k8s.jsonnet.TEMPLATE',
  import 'kube-state-metrics.k8s.jsonnet.TEMPLATE',
  import 'metrics-server.k8s.jsonnet.TEMPLATE',
  import 'prometheus-operator.k8s.jsonnet.TEMPLATE',
  import 'reloader.k8s.jsonnet.TEMPLATE',
  import 'sumologic-fluentd.k8s.jsonnet.TEMPLATE',
  import 'thanos.k8s.jsonnet.TEMPLATE',
  import 'flux.k8s.jsonnet.TEMPLATE',
];

local Manifests(svcs, conf) = [helpers.values(std.prune(s(conf))) for s in svcs];

function(config) {
  apiVersion: 'v1',
  kind: 'List',
  items: std.flattenArrays(Manifests(groups, config)),
}
