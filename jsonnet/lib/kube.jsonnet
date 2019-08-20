{
  local obj = import "obj.jsonnet",

  kubeobj(apiVersion, kind, name):: {
    local this = self,
    apiVersion: apiVersion,
    kind: kind,
    metadata: {
      name: name,
      labels: { name: std.join('-', std.split(this.metadata.name, ':')) },
      annotations: {},
    },
  },

  namespaceName(group, defaultNamespace):: 
    if std.objectHas(group, 'namespace') then group.namespace.name else defaultNamespace,

  labels(config):: if config.cluster.mesh.enabled then
    if config.cluster.mesh.name == 'linkerd' then {
      'linkerd.io/inject': 'disabled',
    } else if config.cluster.mesh.name == 'istio' then {
      'istio-injection': 'disabled',
    },


  helmrelease(config, group):: if group.helmrelease.create then $.kubeobj('flux.weave.works/v1beta1', 'HelmRelease', group.name) {
    local namespace = group.namespace.name,
    local name = group.name,
    metadata+: {
      namespace: namespace,
      annotations: {
        'flux.weave.works/automated': 'false', // XXX
      },
    },
    spec: {
      chart: obj.ignore(group.helmrelease.chart, 'index'),
      releaseName: if name == namespace then name else namespace + '-' + name,
      values: if std.objectHas(group.helmrelease, 'values') then group.helmrelease.values else {},
    },
  },

  secret(config, group, defaultNamespace="default"):: $.kubeobj('v1', 'Secret', group.name) {
    local this = self,
    type: 'Opaque',
    metadata+: {
      namespace: $.namespaceName(group, defaultNamespace),
      labels: {
        cluster: config.cluster.name,
        dest: config.secrets.dest,
      },
    },
    data_:: if std.objectHas(group.secret, 'data_') then group.secret.data_ else {},
    data: { [k]: std.base64(this.data_[k]) for k in std.objectFields(this.data_) },
  },

  namespace(config, group):: $.kubeobj('v1', 'Namespace', group.namespace.name) {
    metadata+: {
      labels: $.labels(config),
    },
  },

  externalSecret(config, group, defaultNamespace="default"):: $.kubeobj('kubernetes-client.io/v1', 'ExternalSecret', group.name) {
    local namespace = $.namespaceName(group, defaultNamespace),
    local key = config.cluster.name + '/' + namespace + '/' + group.name,
    secretDescriptor: {
      backendType: 'secretsManager',
      data: [
        {
          key: key,
          name: name,
          property: name,
        }
        for name in std.objectFieldsAll(group.secret.data_)
      ],
    },
  },
}
