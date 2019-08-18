local helpers = import 'helpers.jsonnet';

local svcs = [
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
];

//{{- if .Values.hydrophone.iamRole }}
//iam.amazonaws.com/role: {{ .Values.hydrophone.iamRole | quote }}
//{{- end }}
//linkerd.io/inject: "{{ .Values.global.cluster.mesh.create }}"

//
// {{- if eq .Values.global.cluster.mesh.name "istio" }}
//   istio-injection: {{ .Values.global.cluster.mesh.create }}
// {{ end }}
// {{- if eq .Values.global.cluster.mesh.name "linkerd" }}
//   global.linkerd.io/inject: {{ .Values.global.cluster.mesh.create }}
// {{- end }}

local host(config, env) =
  if std.objectHas(env.hosts.default, 'host')
  then env.hosts.default.host
  else (
    if env.hosts.default.protocol == 'http'
    then env.hosts.http.dnsNames[0]
    else env.hosts.https.dnsNames[0]
  );

local certificateSecretName(config, env) =
  if std.objectHas(env.hosts.https, 'certificateSecretName')
  then env.hosts.https.certificate.secretName
  else '%s-tls-secret' % env.name;

local bucketName(config, env) =
  if env.bucket.name
  then env.bucket.name
  else 'tidepool-%s-%s-data' % [config.cluster.name, env.name];

local s3URL(config, env) =
  'https://s3-%s.amazonaws.com' % config.cluster.eks.region;

local IamMangedPolicy(config, env) = helpers.iamManagedPolicy(config, env) {
  values+:: {
    Properties+: {
      Statements: [
        {
          Action: 's3:ListBucket',
          Resource: ['arn:aws:s3:::%s/*' % bucketName(config, env)],
          Effect: 'Allow',
        },
        {
          Action: [
            's3:GetObject',
            's3:PutObject',
            's3:DeleteObject',
          ],
          Resource: ['arn:aws:s3:::%s/*' % bucketName(config, env)],
          Effect: 'Allow',
        },
        {
          Effect: 'Allow',
          Action: 'ses:*',
          Resource: '*',
        },
      ],
    },
  },
};

local withGroup(groups, name) = groups[name] { name:: name };


// Compute IAM annotation for group
local iamAnnotations(config, env, group) =
  if std.objectHas(group, 'iam') && group.iam.create
  then (
    local roleName =
      if std.objectHas(group.iam, 'name')
      then group.iam.name
      else '%s-%s-%s' % [config.cluster.name, env.name, group.name];
    {
      deployment+: {
        podAnnotations+: {
          'iam.amazonaws.com/role': roleName,
        },
      },
    }
  )
  else {
  };

local HelmRelease(config, env) = helpers.helmrelease(config, env) {
  local hr = env.helmrelease,
  metadata+: {
    name: 'tidepool',
    namespace: env.name,
    annotations: {
      ['flux.weave.works/tag.' + k]: (hr.gitops.selector + ':' + hr.gitops.filter)
      for k in svcs
    } + {
      'flux.weave.works/automated': hr.gitops.automated,
    },
  },
  spec+: {
    releaseName: env.name + '-tidepool',
    values: helpers.StripSecrets(hr.values) {
      global+: {
        cluster: config.cluster,
        environment+: {
          hosts+: {
            default+: {
              host: host(config, env),
              https+: {
                certificate+: {
                  secretName: certificateSecretName(config, env),
                },
              },
            },
          },
        },
      },
    } + {
      [svc]: (local group = withGroup(env.groups, svc);
        group + iamAnnotations(config, env, group))
      for svc in svcs
    },
  },
};

local HPAs(namespace) = { [namespace + '-' + name + '-HPA']: helpers.hpa(name, namespace) for name in svcs };

function(config) (
  local helmRelease(name, env) = if env.enabled && env.helmrelease.create then HelmRelease(config, env { name: name });
  local helmReleases = std.mapWithKey(helmRelease, config.tidepool.groups);

  local iamManagedPolicy(name, env) = if env.enabled && env.iam.create then IamMangedPolicy(config, env { name: name });
  local iamManagedPolicies = std.mapWithKey(iamManagedPolicy, config.tidepool.groups);

  local iamRole(name, env) = if env.enabled && env.iam.create then helpers.iamRole(config, env);
  local iamRoles = std.mapWithKey(iamManagedPolicy, config.tidepool.groups);

  std.prune(helmReleases + iamManagedPolicies + iamRoles)
)
