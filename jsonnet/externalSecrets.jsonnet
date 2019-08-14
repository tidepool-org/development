local helpers = import 'helpers.jsonnet';

local Helmrelease(config, service) = helpers.helmrelease(config, service) {
  spec+: {
    chart: {
      git: 'git@github.com:godaddy/kubernetes-external-secrets',
      path: 'charts/kubernetes-external-secrets',
      ref: 'master',
      values+: {
        podAnnotations: helpers.roleAnnotation(config, service.name),
      },
    },
  },
};

function(config) {
  local service = config.services.externalSecrets { name: 'externalSecrets' },
  Helmrelease: if service.helmrelease.create then Helmrelease(config, service),
  Namespace: if service.namespace.create then helpers.namespace(config, service),
}
