local helpers = import 'helpers.jsonnet';

local ManagedPolicy(config, group) = helpers.iamManagedPolicy(config, group) {
  values+:: {
    Properties+: {
      PolicyDocument+: {
        Statement: [
          {
            Effect: 'Allow',
            Action: 'route53:ChangeResourceRecordSets',
            Resource: 'arn:aws:route53:::hostedzone/*',
          },
          {
            Effect: 'Allow',
            Action: [
              'route53:GetChange',
              'route53:ListHostedZones',
              'route53:ListResourceRecordSets',
              'route53:ListHostedZonesByName',
            ],
            Resource: '*',
          },
        ],
      },
    },
  },
};

local Helmrelease(config, group) = helpers.helmrelease(config, group) {
  spec+: {
    values+: {
      rbac: {
        create: true,
      },
      logLevel: config.cluster.logLevel,
      aws: {
        region: config.cluster.eks.region,
        zoneType: 'public',
      },
      metrics: {
        enabled: config.cluster.metrics.enabled,
      },
      txtOwnerId: config.cluster.name,
    },
  },
};

function(config) (
  local group = config.groups.externalDNS { name: 'external-dns' };
  if group.enabled then {
    Helmrelease: if group.helmrelease.create then Helmrelease(config, group),
    Namespace: if group.namespace.create then helpers.namespace(config, group),
    Role: if group.cfrole.create then helpers.iamRole(config, group),
    ManagedPolicy: if group.cfmanagedpolicy.create then ManagedPolicy(config, group),
  }
)
