local helpers = import 'helpers.jsonnet';

local ClusterConfig(config) = helpers._Object('eksctl.io/v1alpha5', 'ClusterConfig', config.cluster.name) {
  local cluster = config.cluster,
  metadata+: {
    region: cluster.eks.region,
    version: cluster.k8sVersion,
  },
  vpc: {
    cidr: cluster.eks.cidr,
  },
  nodeGroups: [
    {
      name: 'ng-1',
      instanceType: cluster.eks.nodegroup.instanceType,
      desiredCapacity: cluster.eks.nodegroup.desiredCapacity,
      minSize: cluster.eks.nodegroup.minSize,
      maxSize: cluster.eks.nodegroup.maxSize,
      labels: {
        'kiam-server': 'false',
      },
      tags: {
        'k8s.io/cluster-autoscaler/enabled': 'true',
        ['k8s.io/cluster-autoscaler/' + cluster.name]: 'true',
      },
    },
    {
      name: 'ng-kiam',
      instanceType: cluster.eks.nodegroup.instanceType,
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
