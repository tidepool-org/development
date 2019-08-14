local helpers = import 'helpers.jsonnet';

local Helmrelease(config, service) = helpers.helmrelease(config, 'externalDNS', service) {

  spec+: {
    chart: {
      repository: 'https://kubernetes-charts.storage.googleapis.com/',
      name: 'external-dns',
      version: '1.7.9',
    },
    values+: {
      podAnnotations: helpers.roleAnnotation(config, 'externalDNS'),
      domainfilter: config.company.domain,
      image: {
        name: 'registry.opensource.zalan.do/teapot/external-dns',
        tag: 'latest',
        pullSecrets: {},
      },
      tag: service.values.tag,
      ownerid: 'externalDNS',
      rbac: {
        create: true,
      },
      logLevel: config.cluster.logLevel,
      provider: 'aws',
      awszonetype: 'public',
      aws: {
        region: config.cluster.eks.region,
      },
      txtOwnerId: config.cluster.eks.name,
    },
  },
};

function(config) {
  local service = config.services.externalDNS,
  ExternalDNSHelmrelease: if service.helmrelease.create then Helmrelease(config, service),
  ExternalDNSNamespace: if service.namespace.create then helpers.namespace(config, 'externalDNS', service),
}
