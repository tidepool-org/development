{
  local obj = import "obj.jsonnet",
  local aws = import "aws.jsonnet",

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

  labels(config):: if config.cluster.mesh.enabled then
    if config.cluster.mesh.name == 'linkerd' then {
      'linkerd.io/inject': 'disabled',
    } else if config.cluster.mesh.name == 'istio' then {
      'istio-injection': 'disabled',
    },

  urlrelease(config, group):: $.kubeobj('tidepool/v1beta1', 'URLRelease', group.name) {
    url: group.urlrelease.url,
  },

  helmrelease(config, group):: if group.helmrelease.create then $.kubeobj('flux.weave.works/v1beta1', 'HelmRelease', group.name) {
    local namespace = group.namespace.name,
    local name = group.name,
    metadata+: {
      namespace: namespace,
      annotations: {
        'flux.weave.works/automated': 'false',
      },
    },
    spec: {
      chart: obj.ignore(group.helmrelease.chart, 'index'),
      releaseName: if name == namespace then name else namespace + '-' + name,
      values: {
        podAnnotations: if std.objectHas(group, 'iam') && group.iam.create then aws.roleAnnotation(config, group.name),
      } + if std.objectHas(group.helmrelease, 'values') then group.helmrelease.values else {},
    },
  },

  secret(config, group, defaultNamespace="default"):: $.kubeobj('v1', 'Secret', group.name) {
    local this = self,
    local namespace = if std.objectHas(group, 'namespace') then group.namespace.name else defaultNamespace,
    type: 'Opaque',
    metadata+: {
      namespace: namespace,
      labels: {
        cluster: config.cluster.name,
      },
    },
    data_:: if std.objectHas(group.secret, 'data_') then group.secret.data_ else {},
    data: { [k]: std.base64(this.data_[k]) for k in std.objectFields(this.data_) },
  },

  namespace(config, group):: $.kubeobj('v1', 'Namespace', group.namespace.name) {
    metadata+: {
      labels: $.labels(config),
      annotations: if std.objectHas(group, 'iam') && group.iam.create then aws.permittedAnnotation(config, group.namespace.name),
    },
  },

  externalSecret(config, group, defaultNamespace="default"):: $.kubeobj('kubernetes-client.io/v1', 'ExternalSecret', group.name) {
    local namespace = if std.objectHas(group, 'namespace') then group.namespace.name else defaultNamespace,
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
