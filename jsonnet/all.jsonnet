local groups = [
  import 'autoscaler.jsonnet',
  import 'cert-manager.jsonnet',
  import 'clusterconfig.jsonnet',
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

local name(m) = if m.kind == 'Namespace' || (!std.objectHas(m.metadata, 'namespace')) || m.metadata.name == m.metadata.namespace
then m.metadata.name + '-' + m.kind
else m.metadata.namespace + '-' + m.metadata.name + '-' + m.kind;

local Manifests(svcs, conf) = [std.prune(s(conf)) for s in svcs];

local Rename(m) = { [name(m[field]) + '.json']: m[field] for field in std.objectFields(m) };

function(config) std.foldl(function(x, y) x + Rename(y), Manifests(groups, config), {})
