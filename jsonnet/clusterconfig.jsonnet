local helpers = import 'helpers.jsonnet';

local ClusterConfig(config) = helpers._Object('eksctl.io/v1alpha5', 'ClusterConfig', config.cluster.name) {
  metadata+: {
    region: config.cluster.eks.region,
    version: config.cluster.k8sVersion,
  },
  vpc: {
    cidr: config.cluster.eks.cidr,
  },
  nodeGroups: [
    {
      name: 'ng-1',
      instanceType: config.cluster.eks.nodegroup.instanceType,
      desiredCapacity: config.cluster.eks.nodegroup.desiredCapacity,
      minSize: config.cluster.eks.nodegroup.minSize,
      maxSize: config.cluster.eks.nodegroup.maxSize,
      labels: {
        'kiam-server': 'false',
      },
      tags: {
        'k8s.io/cluster-autoscaler/enabled': 'true',
        ['k8s.io/cluster-autoscaler/' + config.cluster.name]: 'true',
      },
    },
    {
      name: 'ng-kiam',
      instanceType: config.cluster.eks.nodegroup.instanceType,
      desiredCapacity: 1,
      labels: {
        'kiam-server': 'true',
      },
      taints: {
        'kiam-server': 'false:NoExecute',
      },
    },
  ],
};

function(config) {
  ClusterConfig: ClusterConfig(config),
}
