local helpers = import 'helpers.jsonnet';

local Helmrelease(config, service) = helpers.helmrelease(config, 'externalSecrets', service) {
  spec+: {
    chart: {
      git: 'git@github.com:godaddy/kubernetes-external-secrets',
      path: 'charts/kubernetes-external-secrets',
      ref: 'master',
    },
  },
};

function(config) {
  local service = config.services.sumologic,
  ExternalSecretsHelmrelease: if service.helmrelease.create then  Helmrelease(config, service),
  ExternalSecretsNamespace: if service.namespace.create then  helpers.namespace(config, 'externalSecrets', service),
}
