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
  local hr = group.helmrelease,
  metadata+: {
    name: 'tidepool',
    namespace: group.name,
    annotations: {
      ['flux.weave.works/tag.' + k]: (hr.gitops.selector + ':' + hr.gitops.filter)
      for k in svcs
    } + {
      'flux.weave.works/automated': hr.gitops.automated,
    },
  },
  spec+: {
    releaseName: group.name + '-tidepool',
    values: helpers.StripSecrets(hr.values) {
      global+: {
        cluster: config.cluster,
      },
    },
  },
};

local HPAs(namespace) = { [namespace + '-' + name + '-HPA']: helpers.hpa(name, namespace) for name in svcs };

function(config) (
  local converter(name, group) = if group.enabled && group.helmrelease.create then HelmRelease(config, group { name: name });


  // add HPAs
  std.prune(std.mapWithKey(converter, config.tidepool.groups))
)
