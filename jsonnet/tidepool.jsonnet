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

local bucketName(config, env) =
  if env.bucket.name
  then env.bucket.name
  else 'tidepool-%s-%s-data' % [config.cluster.name, env.name];

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

// Compute IAM name
local withIam(config, env, group) =
  if std.objectHas(group, 'iam') && group.iam.create
  then group {
    iam+: { name: if 'name' in super then super.name else '%s-%s-%s' % [config.cluster.name, env.name, group.name] },
  }
  else group;

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
      },
    } + {
      [svc]: withIam(config, env, withGroup(env.groups, svc))
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
