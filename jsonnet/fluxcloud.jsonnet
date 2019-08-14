local helpers = import 'helpers.jsonnet';

local Helmrelease(config, service) = helpers.helmrelease(config, 'fluxcloud', service) {
  local repo(config) = 'https://github.com/%s/cluster-%s' % [config.github.account, config.global.clusterName],
  local channel(config) = '#flux-%s' % [config.global.clusterName],
  spec+: {
    chart: {
      git: 'git@github.com:tidepool-org/development',
      path: 'charts/fluxcloud/0.1.0',
      ref: 'k8s',
    },
    values+: {
      name: 'fluxcloud',
      github: repo(config),
      slack: {
        channel: channel(config),
        username: config.slack.username,
      },
    },
  },
};

function(config) {
  local service = config.services.fluxcloud,
  FluxcloudHelmrelease: if service.helmrelease.create then Helmrelease(config, service),
  FluxcloudSecret: if service.secret.create then helpers.secret(config, 'fluxcloud', service),
}
