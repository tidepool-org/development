local helpers = import 'helpers.jsonnet';

local Helmrelease(config, service) = helpers.helmrelease(config, service) {

  spec+: {
    chart: {
      repository: 'https://kubernetes-charts.storage.googleapis.com/',
      name: 'external-dns',
      version: '1.7.9',
    },
    values+: {
      podAnnotations: helpers.roleAnnotation(config, service.name),
      domainfilter: config.company.domain,
      image: {
        name: 'registry.opensource.zalan.do/teapot/external-dns',
        tag: 'latest',
        pullSecrets: {},
      },
      tag: service.values.tag,
      ownerid: service.name,
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
  local service = config.services.externalDNS { name: 'externalDNS' },
  Helmrelease: if service.helmrelease.create then Helmrelease(config, service),
  Namespace: if service.namespace.create then helpers.namespace(config, service),
}
