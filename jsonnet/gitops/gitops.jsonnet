local groups = [
  import 'slack.k8s.jsonnet.TEMPLATE',
  import 'gitrepo.k8s.jsonnet.TEMPLATE',
];

local Manifests(svcs, conf) = [s(conf) for s in svcs];

function(config) {
  apiVersion: 'v1',
  kind: 'List',
  items: std.flattenArrays(Manifests(groups, config)),
}
