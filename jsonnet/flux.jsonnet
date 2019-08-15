local helpers = import 'helpers.jsonnet';

local HelmRelease(config, group) = helpers.helmrelease(config, group) {
  spec+: {
    chart: {
      repository: 'https://fluxcd.github.io/',
      name: 'flux',
      version: '0.10.2',
    },
    values+: group.helm.values + {
      local path =
        if 'path' in config.gitops.git
        then config.gitops.git.path
        else 'cluster/%s/flux' % config.cluster.name,

      local repoName =
        if 'name' in config.gitops.git
        then config.gitops.git.name
        else 'cluster-%s' % config.cluster.name,

      local branch =
        if 'branch' in config.gitops.git
        then config.gitops.git.branch
        else 'master',

      git: {
        url: '%s/%s' % [config.gitops.git.server, repoName],
        path: path,
        branch: branch,
        label: config.cluster.name,
        secretName: group.secret.name,
      },
      additionalArgs: [
        '--connect=ws://fluxcloud',
      ],
    },
  },
};

function(config) (
  local group = config.groups.flux { name: 'flux' };
  if group.enabled then {
    HelmRelease: HelmRelease(config, group),
    Secret: helpers.secret(config, group),
  }
)
