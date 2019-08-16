local helpers = import 'helpers.jsonnet';

local toUrl(chart) = 
  if std.endsWith(chart.repository, '/')
  then chart.repository
  else '%s/' % chart.repository;

local asRepository(chart) = 
  if std.objectHas(chart, 'repository') then (
    local url = toUrl(chart);
    local uniqKey =  "%s:::%s" % [ url, chart.index ];
    {
      [uniqKey] : {
        caFile: '',
        cache: '%s-index.yaml' % chart.index,
        certFile: '',
        keyFile: '',
        name: chart.index,
        password: '',
        url: url,
        username: '',
      }
    }
 );

local toEntry(name, group) =
  if group.enabled &&
     std.objectHas(group, 'helmrelease') &&
     group.helmrelease.create &&
     std.objectHas(group.helmrelease, 'chart') &&
     (!group.helmrelease.bootstrap)
  then asRepository(group.helmrelease.chart);

local dedup(entries) = std.foldr(function(a,b) if b then a+b else a, entries, {});

local uniqueRepositories(config) = dedup(std.mapWithKey(toEntry, config.groups));

local values(map) = [ map[v] for v in std.objectFields(map)];

local asRepoList(config) = values(uniqueRepositories(config));

local HelmRelease(config, group) = helpers.helmrelease(config, group) {
  spec+: {
    chart: group.helmrelease.chart,
    values+: group.helmrelease.values {
      local path =
        if std.objectHas(config.gitops.git, 'path')
        then config.gitops.git.path
        else 'cluster/%s/flux' % config.cluster.name,

      local repoName =
        if std.objectHas(config.gitops.git, 'name')
        then config.gitops.git.name
        else 'cluster-%s' % config.cluster.name,

      local branch =
        if std.objectHas(config.gitops.git, 'branch')
        then config.gitops.git.branch
        else 'master',

      git: {
        url: '%s/%s' % [config.gitops.git.server, repoName],
        path: path,
        branch: branch,
        label: config.cluster.name,
        secretName: group.secret.name,
      },
      additionalArgs: if config.fluxcloud.enabled then [
        '--connect=ws://fluxcloud',
      ],
      customRepositories: {
        apiVersion: 'v1',
        repositories: asRepoList(config),
      },
    },
  },
};

function(config) (
  local group = config.groups.flux { name: 'flux' };
  if group.enabled then {
    URLRelease: if group.urlrelease.create then helpers.urlrelease(config, group),
    HelmRelease: HelmRelease(config, group),
    Secret: helpers.secret(config, group),
  }
)
