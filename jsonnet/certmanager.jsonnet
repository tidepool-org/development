local helpers = import 'helpers.jsonnet';

local Helmrelease(config, group) = helpers.helmrelease(config, group) {
  spec+: {
    chart: {
      repository: 'https://charts.jetstack.io',
      name: 'cert-manager',
      version: 'v0.8.1',
    }
  },
};

local ClusterIssuer(config, group, server, name) = {
  apiVersion: 'certmanager.k8s.io/v1alpha1',
  kind: 'ClusterIssuer',
  metadata: {
    name: name,
    namespace: group.namespace.name,
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
  local group = config.groups.certmanager { name: 'certmanager' },
  Helmrelease: if group.helmrelease.create then Helmrelease(config, group),
  Namespace: if group.namespace.create then helpers.namespace(config, group),
  StagingClusterIssuer:
    ClusterIssuer(config,
                  group,
                  'https://acme-staging-v02.api.letsencrypt.org/directory',
                  'letsencrypt-staging'),
  ProductionClusterIssuer:
    ClusterIssuer(config,
                  group,
                  'https://acme-v02.api.letsencrypt.org/directory',
                  'letsencrypt-production'),
}
