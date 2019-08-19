{
  local this = self,

  tidepoolServices: [
    'auth',
    'blip',
    'blob',
    'data',
    'export',
    'gatekeeper',
    'highwater',
    'hydrophone',
    'image',
    'jellyfish',
    'messageapi',
    'migrations',
    'notification',
    'seagull',
    'shoreline',
    'task',
    'tidewhisperer',
    'tools',
    'user',
  ],

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

  values(obj):: [obj[field] for field in std.objectFields(obj)],

  bucketName(config, env)::
    if std.objectHas(env.store, 'bucket') && env.store.bucket != ''
    then env.store.bucket
    else 'tidepool-%s-%s-data' % [config.cluster.name, env.name],

  isUpper(c):: (
    local cp = std.codepoint(c);
    cp >= 97 && cp < 123
  ),

  capitalize(word):: (
    assert std.isString(word) : "can only capitalize string";
    local chars = std.stringChars(word);
    std.asciiUpper(chars[0]) + std.foldl( function(a,b) a + b, chars[1:std.length(chars)], "")
  ),

  kebabCase(camelCaseWord):: (
    local merge(a, b) = {
      local isUpper = $.isUpper(b),
      word: (if isUpper && !a.wasUpper then '%s-%s' else '%s%s') % [a.word, std.asciiLower(b)],
      wasUpper: isUpper,
    };
    std.foldl(merge, std.stringChars(camelCaseWord), { word: '', wasUpper: true }).word
  ),

  camelCase(kebabCaseWord, initialUpper=false):: (
    local merge(a, b) = {
      local isHyphen = (b == '-'),
      word: if isHyphen then a.word else a.word + (if a.toUpper then std.asciiUpper(b) else b),
      toUpper: isHyphen,
    };
    std.foldl(merge, std.stringChars(kebabCaseWord), { word: '', toUpper: initialUpper }).word
  ),

  pascalCase(kebabCaseWord):: this.camelCase(kebabCaseWord, true),

  labels(config):: if config.cluster.mesh.enabled then
    if config.cluster.mesh.name == 'linkerd' then {
      'linkerd.io/inject': 'disabled',
    } else if config.cluster.mesh.name == 'istio' then {
      'istio-injection': 'disabled',
    },

  role(config, name):: config.cluster.name + '-' + name + '-role',

  roleAnnotation(config, name):: {
    'iam.amazonaws.com/role': this.role(config, name),
  },

  permittedAnnotation(config, name):: {
    'iam.amazonaws.com/permitted': this.role(config, name),
  },

  urlrelease(config, group):: $._Object('tidepool/v1beta1', 'URLRelease', group.name) {
    url: group.urlrelease.url,
  },

  ignore(x, exclude):: { [f]: x[f] for f in std.objectFieldsAll(x) if f != exclude },

  merge(a, b)::  // merge two objects recursively.  Choose b if conflict.
    if (std.isObject(a) && std.isObject(b))
    then (
      {
        [x]: a[x]
        for x in std.objectFieldsAll(a)
        if !std.objectHas(b, x)
      } + {
        [x]: b[x]
        for x in std.objectFieldsAll(b)
        if !std.objectHas(a, x)
      } + {
        [x]: this.merge(a[x], b[x])
        for x in std.objectFieldsAll(b)
        if std.objectHas(a, x)
      }
    )
    else b,


  iamObject(config, group, iamKind):: {
    local this = self,
    apiVersion:: '2012-10-17',
    kind:: 'AWS::IAM::' + iamKind,
    metadata:: {
      name:: group.name,
    },

    values:: {
      Type: this.kind,
    },
    [self.iamName(config, group, iamKind)]: this.values,
  },

  iamName(config, group, iamKind):: $.capitalize($.camelCase(group.name) + $.camelCase(iamKind)),

  iamManagedPolicy(config, group):: $.iamObject(config, group, 'ManagedPolicy') {
    local this = self,
    values+:: {
      Properties: {
        PolicyDocument: {
          Version: this.apiVersion,
        },
      },
    },
  },

  iamRole(config, group):: $.iamObject(config, group, 'Role') {
    local this = self,
    values+:: {
      Properties: {
        RoleName: '%s-%s-role' % [config.cluster.name, group.name],
        ManagedPolicyArns: {
          Ref: $.iamName(config, group, 'ManagedPolicy'),
        },
        AssumeRolePolicyDocument: {
          Version: this.apiVersion,
          Statement: [
            {
              Action: 'sts:AssumeRole',
              Effect: 'Allow',
              Principal: {
                Service: 'ec2.amazonaws.com',
              },
            },
            {
              Action: 'sts:AssumeRole',
              Effect: 'Allow',
              Principal: {
                AWS: {
                  'Fn::GetAtt': [
                    $.iamName(config, config.groups.kiam, 'Role'),
                    'Arn',
                  ],
                },
              },
            },
          ],
        },
      },
    },
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
      chart: this.ignore(group.helmrelease.chart, 'index'),
      releaseName: if name == namespace then name else namespace + '-' + name,
      values: {
        podAnnotations: if std.objectHas(group, 'iam') && group.iam.create then this.roleAnnotation(config, group.name),
      } + if std.objectHas(group.helmrelease, 'values') then group.helmrelease.values else {},
    },
  },

  secretEntry(config, group, entry):: $._Object('v1', 'Secret', group[entry].name) {
    local secret = group[entry],
    type: 'Opaque',
    metadata+: {
      namespace: group.namespace.name,
    },
    data_:: {},
    data: { [k]: std.base64(secret.data_[k]) for k in std.objectFieldsAll(secret.data_) },
  },

  secret(config, group):: $._Object('v1', 'Secret', group.name) {
    local secret = self,
    type: 'Opaque',
    metadata+: {
      namespace: group.namespace.name,
    },
    data_:: {},
    data: { [k]: std.base64(secret.data_[k]) for k in std.objectFieldsAll(secret.data_) },
  },

  namespace(config, group):: $._Object('v1', 'Namespace', group.namespace.name) {
    metadata+: {
      labels: this.labels(config),
      annotations: if std.objectHas(group, 'iam') && group.iam.create then this.permittedAnnotation(config, group.namespace.name),
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
        for name in std.objectFieldsAll(group.secret.data_)
      ],
    },
  },

  stripSecrets(obj)::
    { [k]: obj[k] for k in std.objectFieldsAll(obj) if k != 'secret' && !std.isObject(obj[k]) } +
    { [k]: this.stripSecrets(obj[k]) for k in std.objectFieldsAll(obj) if k != 'secret' && std.isObject(obj[k]) },

  StripSecrets(obj):: std.prune(this.stripSecrets(obj)),
}
