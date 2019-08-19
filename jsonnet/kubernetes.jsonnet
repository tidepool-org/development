local helpers = import 'helpers.jsonnet';

local groups = [
  import 'autoscaler.jsonnet',
  import 'cert-manager.jsonnet',
  import 'datadog-agent.jsonnet',
  import 'external-dns.jsonnet',
  import 'external-secrets.jsonnet',
  import 'fluxcloud.jsonnet',
  import 'gloo.jsonnet',
  import 'kiam.jsonnet',
  import 'kube-state-metrics.jsonnet',
  import 'metrics-server.jsonnet',
  import 'prometheus-operator.jsonnet',
  import 'reloader.jsonnet',
  import 'sumologic-fluentd.jsonnet',
  import 'tidepool.jsonnet',
  import 'thanos.jsonnet',
  import 'flux.jsonnet',
];

local Manifests(svcs, conf) = [ helpers.values(std.prune(s(conf))) for s in svcs];

function(config) {
  apiVersion: "v1",
  kind: "List",
  items: std.flattenArrays(Manifests(groups, config))
}
