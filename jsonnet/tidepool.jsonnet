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

local HelmRelease(config, name, service) = helpers.helmrelease(config, name, service) {
  metadata+: {
    name: 'tidepool',
    namespace: name,
    annotations: {
      ['flux.weave.works/tag.' + k]: (service.gitops.selector + ':' + service.gitops.filter)
      for k in svcs
    } + {
      'flux.weave.works/automated': service.gitops.automated,
    },
  },
  spec: {
    releaseName: name + '-tidepool',
    chart: {
      git: 'git@github.com:tidepool-org/development',
      path: 'charts/tidepool/0.1.7',
      ref: 'k8s',
    },
    values: service.values {
      globals: {
        cluster: config.cluster,
      },
    },
  },
};

local HPAs(namespace) = { [namespace + "-" + name+ "-HPA"] : helpers.hpa(name, namespace) for name in svcs };

function(config) (
  local converter(name, service) = if service.helmrelease.create then HelmRelease(config, name, service);
  // add HPAs
  // add externalSecrets
  std.prune(std.mapWithKey(converter, config.tidepool.services))
)
