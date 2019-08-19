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

local s3URL(config, env) =
  'https://s3-%s.amazonaws.com' % config.cluster.eks.region;


local roleRequired(config, group) =
  config.groups.kiam.enabled && std.objectHas(group, 'iamRole') && group.iamRole.create;

local iamPermissions(config, env) =
  if config.groups.kiam.enabled
  then {
    'iam.amazonaws.com/permitted': '%s/.*' % env.name,
  } else {
  };

local withGroup(groups, name) = (groups[name] { name: name });

// Compute IAM annotation for group
local iamAnnotations(config, env, group) = (
  local clusterName = config.cluster.name;
  local envName = env.name;
  local groupName = group.name;
  if roleRequired(config, group)
  then {
    deployment+: {
      podAnnotations+: {
        'iam.amazonaws.com/role': '%s-%s-%s' % [clusterName, envName, groupName],
      },
    },
  } else {
  }
);

// Compute Linkerd annotations
local linkerdAnnotations(config, env, group) =
  if config.cluster.mesh.enabled && config.cluster.mesh.name == 'linkerd'
  then {
    deployment+: {
      podAnnotations+: {
        'linkerd.io/inject': 'enabled',
      },
    },
  }
  else {
  };

local combine(config, env, group, key) = {
  [key]+:
    std.foldl(helpers.merge, [
      config.cluster[key],
      if std.objectHas(env, key) then env[key] else {},
      if std.objectHas(group, key) then group[key] else {},
    ], {}),
};

local resources(config, env, group) = combine(config, env, group, 'resources');

local securityContext(config, env, group) = combine(config, env, group, 'securityContext');

local deployment(config, env, group) =
   if std.objectHas(group, 'deployment') && std.objectHas(group.deployment, 'env')
   then {
     deployment+: {
       env+: combine(config, env, group.deployment.env, 'store')
     }  
   }
   else {
   };


local hpas(config, env, group) = combine(config, env, group, 'hpa');

// add default bucket
local getBucket(config, env) =
  {
    store+: {
      bucket: helpers.bucketName(config, env),
    },
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
        annotations+: iamPermissions(config, env),
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
      [svc]: (
        local group = withGroup(env.groups, svc);
        local envWithBucket = env + getBucket(config, env);
        group
        + iamAnnotations(config, envWithBucket, group)
        + linkerdAnnotations(config, envWithBucket, group)
        + securityContext(config, envWithBucket, group)
        + resources(config, envWithBucket, group)
        + deployment(config, envWithBucket, group)
        + hpas(config, envWithBucket, group)
      )
      for svc in helpers.tidepoolServices
    },
  },
};

function(config) (
  local helmRelease(name, env) = if env.enabled then HelmRelease(config, env { name: name });
  local helmReleases = std.mapWithKey(helmRelease, config.tidepool.groups);
  std.prune(helmReleases)
)
