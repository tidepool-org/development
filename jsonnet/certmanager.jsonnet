local helpers = import 'helpers.jsonnet';

local Helmrelease(config, service) =
  helpers.helmrelease(config, 'certmanager', service) {
    spec+: {
      chart: {
        repository: 'https://charts.jetstack.io',
        name: 'cert-manager',
        version: 'v0.8.1',
      },
      values+: {
        podAnnotations: helpers.roleAnnotation(config, 'certmanager'),
      },
    },
  };

local ClusterIssuer(config, service, server, name) = {
  apiVersion: 'certmanager.k8s.io/v1alpha1',
  kind: 'ClusterIssuer',
  metadata: {
    name: name,
    namespace: service.namespace.name,
  },
  spec: {
    acme: {
      server: server,
      email: config.company.email,
      privateKeySecretRef: {
        name: name,
      },
      solvers: [
        {
          dns01: {
            route53: {
              region: config.cluster.eks.region,
            },
          },
        },
      ],
    },
  },
};

function(config) {
  local service = config.services.certmanager,
  certmanagerHelmrelease: if service.helmrelease.create then Helmrelease(config, service),
  certmanagerNamespace: if service.namespace.create then helpers.namespace(config, 'certmanager', service),
  certmanagerStagingClusterissuer:
    ClusterIssuer(config, service,
                  'https://acme-staging-v02.api.letsencrypt.org/directory',
                  'letsencrypt-staging'),
  certmanagerProductionClusterissuer:
    ClusterIssuer(config, service,
                  'https://acme-v02.api.letsencrypt.org/directory',
                  'letsencrypt-production'),
}
