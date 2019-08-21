{
  contains(list, value):: std.foldl(function(a,b) (a || (b == value)), list, false),
  
  values(obj):: [obj[field] for field in std.objectFields(obj)],

  ignore(x, exclude):: { [f]: x[f] for f in std.objectFieldsAll(x) if f != exclude },

  merge(a, b)::  // merge two objects recursively.  Choose b if conflict.
    if (std.isObject(a) && std.isObject(b))
    then (
      {
        [x]: a[x]
        for x in std.objectFieldsAll(a)
        if !std.objectHas(b, x)
      } + {
        [x]: b[x]
        for x in std.objectFieldsAll(b)
        if !std.objectHas(a, x)
      } + {
        [x]: $.merge(a[x], b[x])
        for x in std.objectFieldsAll(b)
        if std.objectHas(a, x)
      }
    )
    else b,

  strip(obj, list)::
    { [k]: obj[k] for k in std.objectFieldsAll(obj) if ! $.contains(list, k) && !std.isObject(obj[k]) } +
    { [k]: $.strip(obj[k], list) for k in std.objectFieldsAll(obj) if ! $.contains(list, k) && std.isObject(obj[k]) },
}
