{
  local this = self,

  _Object(apiVersion, kind, name):: {
    local this = self,
    apiVersion: apiVersion,
    kind: kind,
    metadata: {
      name: name,
      labels: { name: std.join("-", std.split(this.metadata.name, ":")) },
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

  helmrelease(config, name, service):: $._Object('flux.weave.works/v1beta1', 'HelmRelease', name) {
    local namespace = service.namespace.name,
    metadata+: {
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

  secret(config, name, service):: $._Object('v1', 'Secret', name) {
    local secret = self,
    type: 'Opaque',
    metadata+: {
      namespace: service.namespace.name,
    },
    data_:: {},
    data: { [k]: std.base64(secret.data_[k]) for k in std.objectFields(secret.data_) },
  },

  namespace(config, name, service):: $._Object('v1', 'Namespace', service.namespace.name) {
    metadata+: {
      labels: this.labels(config),
      annotations: this.permittedAnnotation(config, service.namespace.name),
    },
  },

  externalSecret(config, env, base, service):: $._Object('kubernetes-client.io/v1', 'ExternalSecret', base) {
    local  key = config.eks.cluster.name + "/" + env + "/" + base,
    secretDescriptor : {
      backendType: "secretsManager",
      data: [ 
        {
          key: key,
          name: name,
          property: name
        } for name in std.objectFields(service.secret.data_)
      ]
    }
  },

  hpa(name, namespace, min=1, max=10, targetCPUUtilizationPercentage=50):: $._Object('autoscaling/v1', 'HorizontalPodAutoscaler', name) {
    metadata+: {
      namespace: namespace
    },
    spec+: {
      maxReplicas: max,
      minReplicas: min,
      scaleTargetRef: {
        apiVersion: "extensions/v1beta1",
        kind: "Deployment",
        name: name
      },
      targetCPUUtilizationPercentage: targetCPUUtilizationPercentage 
    }
  }
}