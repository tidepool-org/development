local config = import 'values.json';

local services = [
  import 'autoscaler.jsonnet',
  import 'certmanager.jsonnet',
  import 'datadog.jsonnet',
  import 'externalDNS.jsonnet',
  import 'fluxcloud.jsonnet',
  import 'gloo.jsonnet',
  import 'kiam.jsonnet',
  import 'kubeStateMetrics.jsonnet',
  import 'metricsServer.jsonnet',
  import 'prometheusOperator.jsonnet',
  import 'reloader.jsonnet',
  import 'sumologic.jsonnet',
  import 'tidepool.jsonnet',
  //import 'thanos.jsonnet',
];

local name(m) = if m.kind == 'Namespace' || m.metadata.name == m.metadata.namespace
then m.metadata.name + '-' + m.kind
else m.metadata.namespace + '-' + m.metadata.name + '-' + m.kind;

local Manifests(svcs, conf) = [std.prune(s(conf)) for s in svcs];

local Rename(m) = { [name(m[field]) + '.json']: m[field] for field in std.objectFields(m) };

std.foldl(function(x, y) x + Rename(y), Manifests(services, config), {})
