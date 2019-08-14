local helpers = import 'helpers.jsonnet';

local Helmrelease(config, service) = helpers.helmrelease(config, 'externalSecrets', service) {
  spec+: {
    chart: {
      git: 'git@github.com:godaddy/kubernetes-external-secrets',
      path: 'charts/kubernetes-external-secrets',
      ref: 'master',
      values+: {
        podAnnotations: helpers.roleAnnotation(config, 'externalSecrets'),
      },
    },
  },
};

function(config) {
  local service = config.services.sumologic,
  Helmrelease: if service.helmrelease.create then Helmrelease(config, service),
  Namespace: if service.namespace.create then helpers.namespace(config, 'externalSecrets', service),
}
