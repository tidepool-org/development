{
  local this = self,

  labels:: function(config) if config.cluster.mesh.create then
    if config.cluster.mesh.name == 'linkerd' then {
      'linkerd.io/inject': 'disabled',
    } else if config.cluster.mesh.name == 'istio' then {
      'istio-injection': 'disabled',
    },

  role:: function(config, name) config.cluster.eks.name + '-' + name + '-role',

  roleAnnotation:: function(config, name) {
    'iam.amazonaws.com/role': this.role(config, name),
  },

  permittedAnnotation:: function(config, name) {
    'iam.amazonaws.com/permitted': this.role(config, name),
  },

  helmrelease:: function(config, name, service) {
    local namespace = service.namespace.name,
    apiVersion: 'flux.weave.works/v1beta1',
    kind: 'HelmRelease',
    metadata: {
      name: name,
      namespace: namespace,
      annotations: {
        'flux.weave.works/automated': 'false',
      },
    },
    spec: {
      releaseName: if name == namespace then name else namespace + '-' + name,
      values: {},
    },
  },

  secret:: function(config, name, service) {
    local namespace = service.namespace.name,
    local secret = self,
    apiVersion: 'v1',
    kind: 'Secret',
    metadata: {
      name: name,
      namespace: namespace,
    },
    data_:: {},
    data: { [k]: std.base64(secret.data_[k]) for k in std.objectFields(secret.data_) },
  },

  namespace:: function(config, name, service) {
    local namespace = service.namespace.name,
    apiVersion: 'v1',
    kind: 'Namespace',
    metadata: {
      name: namespace,
      labels: this.labels(config),
      annotations: this.permittedAnnotation(config, namespace),
    },
  },
}
