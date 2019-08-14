local helpers = import 'helpers.jsonnet';

local Helmrelease(config, service) =
  helpers.helmrelease(config, service) {
    spec+: {
      chart: {
        repository: 'https://charts.jetstack.io',
        name: 'cert-manager',
        version: 'v0.8.1',
      },
      values+: {
        podAnnotations: helpers.roleAnnotation(config, service.name),
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
  local service = config.services.certmanager { name: 'certmanager' },
  Helmrelease: if service.helmrelease.create then Helmrelease(config, service),
  Namespace: if service.namespace.create then helpers.namespace(config, service),
  StagingClusterIssuer:
    ClusterIssuer(config,
                  service,
                  'https://acme-staging-v02.api.letsencrypt.org/directory',
                  'letsencrypt-staging'),
  ProductionClusterIssuer:
    ClusterIssuer(config,
                  service,
                  'https://acme-v02.api.letsencrypt.org/directory',
                  'letsencrypt-production'),
}
