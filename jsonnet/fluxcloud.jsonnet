local helpers = import 'helpers.jsonnet';

local Helmrelease(config, group) = helpers.helmrelease(config, group) {
  local gitops = config.gitops,
  local repoBase =
    if std.objectHas(gitops.git, 'name')
    then gitops.git.name
    else 'cluster-%s' % config.cluster.name,
  local repoName = '%s/%s' % [gitops.git.server, repoBase],
  local channelName =
    if std.objectHas(gitops.notifications.slack, 'channel')
    then gitops.notifications.slack.channel
    else '#flux-%s' % config.cluster.name,

  spec+: {
    chart: {
      git: 'git@github.com:tidepool-org/development',
      path: 'charts/fluxcloud/0.1.0',
      ref: 'k8s',
    },
    values+: {
      name: group.name,
      github: repoName,
      slack: {
        channel: channelName,
        username: gitops.notifications.slack.username,
      },
      secretName: group.secret.name,
    },
  },
};

function(config) (
  local group = config.groups.fluxcloud;
  if group.enabled then {
    Helmrelease: if group.helmrelease.create then Helmrelease(config, group),
    Secret: if group.secret.create then helpers.secret(config, group),
  }
)
