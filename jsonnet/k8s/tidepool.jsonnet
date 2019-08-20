local helpers = import 'helpers.jsonnet';

local groups = [
  import 'tidepool.k8s.jsonnet.TEMPLATE',
];

local Manifests(svcs, conf) = [ helpers.values(std.prune(s(conf))) for s in svcs];

function(config) {
  apiVersion: "v1",
  kind: "List",
  items: std.flattenArrays(Manifests(groups, config))
}
