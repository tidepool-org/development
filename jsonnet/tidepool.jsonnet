local helpers = import 'helpers.jsonnet';

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

local roleRequired(config, group) = 
 config.groups.kiam.enabled && std.objectHas(group, 'iamRole') && group.iamRole.create;

local iamPermissions(config, env) = 
  if config.groups.kiam.enabled
  then {
    "iam.amazonaws.com/permitted": "%s/.*" % env.name
  } else {
  };

local withGroup(groups, name) = groups[name] { name:: name };

// Compute IAM annotation for group
local iamAnnotations(config, env, group) =
  if roleRequired(config, env, group)
  then {
    deployment+: {
      podAnnotations+: {
        'iam.amazonaws.com/role':  '%s-%s-%s' % [config.cluster.name, env.name, group.name],
      }
    }
  } else {
  };

// Compute Linkerd annotations
local linkerdAnnotations(config, env, group) =
  if config.cluster.mesh.enabled && config.cluster.mesh.name == "linkerd"
  then {
    deployment+: {
      podAnnotations+: {
        'linkerd.io/inject': "enabled",
      },
    },
  }
  else {
  };

local HelmRelease(config, env) = helpers.helmrelease(config, env) {
  local hr = env.helmrelease,
  metadata+: {
    name: 'tidepool',
    namespace: env.name,
    annotations: {
      ['flux.weave.works/tag.' + k]: (hr.gitops.selector + ':' + hr.gitops.filter)
      for k in helpers.tidepoolServices
    } + {
      'flux.weave.works/automated': hr.gitops.automated,
    },
  },
  spec+: {
    releaseName: env.name + '-tidepool',
    values: helpers.StripSecrets(hr.values) {
      namespace+: {
        annotations+: iamPermissions(config, env)
      },
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
        group + iamAnnotations(config, env, group) + linkerdAnnotations(config, env, group))
      for svc in helpers.tidepoolServices
    },
  },
};

local HPAs(namespace) = { [namespace + '-' + name + '-HPA']: helpers.hpa(name, namespace) for name in helpers.tidepoolServices };

function(config) (
  local helmRelease(name, env) = if env.enabled && env.helmrelease.create then HelmRelease(config, env { name: name });
  local helmReleases = std.mapWithKey(helmRelease, config.tidepool.groups);

  local iamManagedPolicy(name, env) = if env.enabled && env.iam.create then IamMangedPolicy(config, env { name: name });
  local iamManagedPolicies = std.mapWithKey(iamManagedPolicy, config.tidepool.groups);

  local iamRole(name, env) = if env.enabled && env.iam.create then helpers.iamRole(config, env);
  local iamRoles = std.mapWithKey(iamManagedPolicy, config.tidepool.groups);

  std.prune(helmReleases + iamManagedPolicies + iamRoles)
)
