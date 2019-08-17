local helpers = import 'helpers.jsonnet';

local ManagedPolicy(config, group) = helpers.iamManagedPolicy(config, group) {
  values+:: {
    Properties+: {
      PolicyDocument+: {
        Statement: [
          {
            Effect: 'Allow',
            Action: 'secretsmanager:GetSecretValue',
            Resource: [
              'arn:aws:secretsmanager:%s:%s:secret:%s/*' % [config.cluster.eks.region, config.cluster.eks.accountNumber, config.cluster.name],
            ],
          },
        ],
      },
    },
  },
};

function(config) (
  local group = config.groups.externalSecrets { name: 'external-secrets' };
  if group.enabled then {
    Helmrelease: if group.helmrelease.create then helpers.helmrelease(config, group),
    Namespace: if group.namespace.create then helpers.namespace(config, group),
    ManagedPolicy: if group.cfmanagedpolicy.create then ManagedPolicy(config, group),
    Role: if group.cfrole.create then helpers.iamRole(config, group),
  }
)
