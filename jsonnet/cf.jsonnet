local helpers = import 'helpers.jsonnet';

local groups = [
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

local Rename(m) = { 
  [name(m[field]) + '.cf']: m[field] for field in std.objectFields(m) 
  };

function(config)
  std.foldl(function(x, y) x + Rename(y), Manifests(groups, config), {})

