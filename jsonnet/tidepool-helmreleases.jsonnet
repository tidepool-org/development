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

local toEnvironment(name, environment, config) = {
  kind: 'HelmRelease',
  apiVersion: 'flux.weave.works/v1beta1',
  metadata: {
    name: 'tidepool',
    namespace: name,
    annotations: {
      ['flux.weave.works/tag.' + k]: (environment.gitops.selector + ':' + environment.gitops.filter)
      for k in svcs
    } + {
      "flux.weave.works/automated": environment.gitops.automated
    },
  },
  spec: {
    releaseName: name + '-tidepool',
    chart: {
      git: 'git@github.com:tidepool-org/development',
      path: 'charts/tidepool/0.1.7',
      ref: 'k8s',
    },
    values: {
              global: {
                fullnameOverride: '',
                nameOverride: '',
                cluster: {
                  region: config.cluster.eks.region,
                  name: config.cluster.eks.name,
                  mesh: config.cluster.mesh,
                  gateway: config.cluster.gateway,
                  logLevel: config.cluster.logLevel,
                },
              } + environment.global,
            } + environment.sharedInternalSecrets
            + environment.tidepoolServices
            + environment.thirdPartyInternalServices
            + environment.externallySharedSecrets,
  },
};

function(config) (
  local converter(name, environment) = toEnvironment(name, environment, config);
  local helmreleases =  std.prune(std.mapWithKey(converter, config.environments));
  
  {
    [k + '-helmrelease.json']: helmreleases[k] for k in std.objectFields(helmreleases)
  }
)
