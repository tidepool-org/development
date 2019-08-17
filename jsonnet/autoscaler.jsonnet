local helpers = import 'helpers.jsonnet';

local ManagedPolicy(config, group) = helpers.iamManagedPolicy(config, group) {
  values+:: {
    Properties+: {
      PolicyDocument+: {
        Statement: [
          {
            Effect: 'Allow',
            Action: [
              'autoscaling:DescribeAutoScalingInstances',
              'autoscaling:SetDesiredCapacity',
              'autoscaling:DescribeAutoScalingGroups',
              'autoscaling:DescribeTags',
              'autoscaling:DescribeLaunchConfigurations',
              'autoscaling:TerminateInstanceInAutoScalingGroup',
            ],
            Resource: '*',
          },
        ],
      },
    },
  },
};

local Role(config, group) = helpers.iamRole(config, group) {
  values+:: {
    Properties+: {
      ManagedPolicyArns: {
        Ref: helpers.iamName(config, group, 'ManagedPolicy'),
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
      autoDiscovery: {
        clusterName: config.cluster.name,
      },
      awsRegion: config.cluster.eks.region,
      serviceMonitor: {
        enabled: true,
      },
      sslCertHostPath: '/etc/ssl/certs/ca-bundle.crt',
      extraArgs: {
        v: 4,
        stderrthreshold: 'info',
        logtostderr: true,
        'skip-nodes-with-local-storage': false,
      },
    },
  },
};

function(config) (
  local group = config.groups.autoscaler { name: 'autoscaler' };
  if group.enabled then {
    Helmrelease: if group.helmrelease.create then Helmrelease(config, group),
    Namespace: if group.namespace.create then helpers.namespace(config, group),
  }
)
