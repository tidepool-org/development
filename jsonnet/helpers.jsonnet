{
  local this = self,

  _Object(apiVersion, kind, name):: {
    local this = self,
    apiVersion: apiVersion,
    kind: kind,
    metadata: {
      name: name,
      labels: { name: std.join('-', std.split(this.metadata.name, ':')) },
      annotations: {},
    },
  },

  labels(config):: if config.cluster.mesh.create then
    if config.cluster.mesh.name == 'linkerd' then {
      'linkerd.io/inject': 'disabled',
    } else if config.cluster.mesh.name == 'istio' then {
      'istio-injection': 'disabled',
    },

  role(config, name):: config.cluster.eks.name + '-' + name + '-role',

  roleAnnotation(config, name):: {
    'iam.amazonaws.com/role': this.role(config, name),
  },

  permittedAnnotation(config, name):: {
    'iam.amazonaws.com/permitted': this.role(config, name),
  },

  helmrelease(config, group):: $._Object('flux.weave.works/v1beta1', 'HelmRelease', group.name) {
    local namespace = group.namespace.name,
    local name = group.name,
    metadata+: {
      namespace: namespace,
      annotations: {
        'flux.weave.works/automated': 'false',
      },
    },
    spec: {
      releaseName: if name == namespace then name else namespace + '-' + name,
      values: {
          podAnnotations: if 'iam' in group && group.iam.create then this.roleAnnotation(config, group.name),
      }
    },
  },

  secret(config, group):: $._Object('v1', 'Secret', group.name) {
    local secret = self,
    type: 'Opaque',
    metadata+: {
      namespace: group.namespace.name,
    },
    data_:: {},
    data: { [k]: std.base64(secret.data_[k]) for k in std.objectFields(secret.data_) },
  },

  namespace(config, group):: $._Object('v1', 'Namespace', group.namespace.name) {
    metadata+: {
      labels: this.labels(config),
      annotations: if 'iam' in group && group.iam.create then this.permittedAnnotation(config, group.namespace.name),
    },
  },

  externalSecret(config, env, group):: $._Object('kubernetes-client.io/v1', 'ExternalSecret', group.name) {
    local key = config.eks.cluster.name + '/' + env + '/' + group.name,
    secretDescriptor: {
      backendType: 'secretsManager',
      data: [
        {
          key: key,
          name: name,
          property: name,
        }
        for name in std.objectFields(group.secret.data_)
      ],
    },
  },

  hpa(config, group, min=1, max=10, targetCPUUtilizationPercentage=50):: $._Object('autoscaling/v1', 'HorizontalPodAutoscaler', group.name) {
    metadata+: {
      namespace: group.namespace.name,
    },
    spec+: {
      maxReplicas: max,
      minReplicas: min,
      scaleTargetRef: {
        apiVersion: 'extensions/v1beta1',
        kind: 'Deployment',
        name: group.name,
      },
      targetCPUUtilizationPercentage: targetCPUUtilizationPercentage,
    },
  },
}