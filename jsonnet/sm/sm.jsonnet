local groups = [
  import 'secrets-manager.cf.jsonnet.TEMPLATE',
];

local Manifests(svcs, conf) = [std.prune(s(conf)) for s in svcs];

local resources(config) =
  std.foldl(
    function(a, b) a + b,
    std.flattenArrays(Manifests(groups, config)),
    {}
  );

local CFTemplate(config) = {
  kind: "CFTemplate",
  apiVersion: "tidepool/v1beta1",
  data: {
    AWSTemplateFormatVersion: "2010-09-09",
    Description: "Cluster %s" % config.cluster.name,
    Resources: resources(config)
  }
};

function(config) CFTemplate(config)
