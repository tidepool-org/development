local helpers = import 'helpers.jsonnet';

local ClusterConfig(config) = {
  apiVersion: 'eksctl.io/v1alpha5',
  kind: 'ClusterConfig',
  metadata: {
    name: config.cluster.eks.name,
    region: config.cluster.eks.region,
    version: config.cluster.eks.k8sVersion,
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
        ['k8s.io/cluster-autoscaler/' + config.cluster.eks.name]: 'true',
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
