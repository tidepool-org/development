local helpers = import 'helpers.jsonnet';

local groups = [
  import 'autoscaler.cf.jsonnet.TEMPLATE',
  import 'cert-manager.cf.jsonnet.TEMPLATE',
  import 'external-dns.cf.jsonnet.TEMPLATE',
  import 'external-secrets.cf.jsonnet.TEMPLATE',
  import 'kiam.cf.jsonnet.TEMPLATE',
  import 'tidepool.cf.jsonnet.TEMPLATE',
];

local Manifests(svcs, conf) = [std.prune(s(conf)) for s in svcs];

function(config)
  std.foldr(
    function(a, b) a + b,
    std.flattenArrays(Manifests(groups, config)),
    {}
  )
