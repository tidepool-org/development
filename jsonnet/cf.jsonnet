local helpers = import 'helpers.jsonnet';

local groups = [
  import 'autoscaler.cf.jsonnet.TEMPLATE',
  import 'cert-manager.cf.jsonnet.TEMPLATE',
  import 'external-dns.cf.jsonnet.TEMPLATE',
  import 'external-secrets.cf.jsonnet.TEMPLATE',
  import 'kiam.cf.jsonnet.TEMPLATE',
  import 'tidepool.cf.jsonnet.TEMPLATE',
];

local name(m) = if m.kind == 'Namespace' || (!std.objectHas(m.metadata, 'namespace')) || m.metadata.name == m.metadata.namespace
then m.metadata.name + '-' + m.kind
else m.metadata.namespace + '-' + m.metadata.name + '-' + m.kind;

local Manifests(svcs, conf) = [std.prune(s(conf)) for s in svcs];

function(config) (
  local manifests = Manifests(groups, config);
  std.foldl(function(x, y) x + y, manifests, [])
)
