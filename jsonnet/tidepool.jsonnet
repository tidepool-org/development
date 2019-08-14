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

local HelmRelease(config, group) = helpers.helmrelease(config, group) {
  metadata+: {
    name: 'tidepool',
    namespace: group.name,
    annotations: {
      ['flux.weave.works/tag.' + k]: (group.gitops.selector + ':' + group.gitops.filter)
      for k in svcs
    } + {
      'flux.weave.works/automated': group.gitops.automated,
    },
  },
  spec: {
    releaseName: group.name + '-tidepool',
    chart: {
      git: 'git@github.com:tidepool-org/development',
      path: 'charts/tidepool/0.1.7',
      ref: 'k8s',
    },
    values: group.values {
      globals: {
        cluster: config.cluster,
      },
    },
  },
};

local HPAs(namespace) = { [namespace + '-' + name + '-HPA']: helpers.hpa(name, namespace) for name in svcs };

function(config) (
  local converter(name, group) = if group.helmrelease.create then HelmRelease(config, group { name: 'tidepool-' + name });


  // add HPAs
  // add externalSecrets
  std.prune(std.mapWithKey(converter, config.tidepool.groups))
)
