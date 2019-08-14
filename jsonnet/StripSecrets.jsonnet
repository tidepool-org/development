local stripSecrets(obj) =
  { [k]: obj[k] for k in std.objectFields(obj) if k != 'secret' && !std.isObject(obj[k]) } +
  { [k]: stripSecrets(obj[k]) for k in std.objectFields(obj) if k != 'secret' && std.isObject(obj[k]) };

function(obj) (
  std.prune(stripSecrets(obj))
)
