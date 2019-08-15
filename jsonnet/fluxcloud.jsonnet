local helpers = import 'helpers.jsonnet';

local Helmrelease(config, group) = helpers.helmrelease(config, group) {
  local repo(config) = 'https://github.com/%s/cluster-%s' % [config.github.account, config.global.clusterName],
  local channel(config) = '#flux-%s' % [config.global.clusterName],
  spec+: {
    chart: {
      git: 'git@github.com:tidepool-org/development',
      path: 'charts/fluxcloud/0.1.0',
      ref: 'k8s',
    },
    values+: {
      name: group.name,
      github: repo(config),
      slack: {
        channel: channel(config),
        username: config.slack.username,
      },
      secretName: group.secret.name,
    },
  },
};

function(config) (
  local group = config.groups.fluxcloud { name: 'fluxcloud' };
  if group.enabled then {
    Helmrelease: if group.helmrelease.create then Helmrelease(config, group),
    Secret: if group.secret.create then helpers.secret(config, group),
  }
)
