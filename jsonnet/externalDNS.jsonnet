local helpers = import 'helpers.jsonnet';

local Helmrelease(config, group) = helpers.helmrelease(config, group) {
  spec+: {
    values+: {
      domainfilter: config.company.domain,
      image: {
        name: 'registry.opensource.zalan.do/teapot/external-dns',
        tag: 'latest',
        pullSecrets: {},
      },
      tag: group.helmrelease.data.tag,
      ownerid: group.name,
      rbac: {
        create: true,
      },
      logLevel: config.cluster.logLevel,
      provider: 'aws',
      awszonetype: 'public',
      aws: {
        region: config.cluster.eks.region,
      },
      txtOwnerId: config.cluster.name,
    },
  },
};

function(config) (
  local group = config.groups.externalDNS { name: 'externalDNS' };
  if group.enabled then {
    Helmrelease: if group.helmrelease.create then Helmrelease(config, group),
    Namespace: if group.namespace.create then helpers.namespace(config, group),
  }
)
