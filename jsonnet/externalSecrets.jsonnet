local helpers = import 'helpers.jsonnet';

function(config) (
  local group = config.groups.externalSecrets { name: 'externalSecrets' };
  if group.enabled then {
    Helmrelease: if group.helmrelease.create then helpers.helmrelease(config, group),
    Namespace: if group.namespace.create then helpers.namespace(config, group),
  }
)
