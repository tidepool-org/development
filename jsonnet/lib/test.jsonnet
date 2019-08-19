local helpers = import "helpers.jsonnet";

local a = {
  secret: "b",
  c:  {
    e: 134,
    secret: {
       d: "e"
    }
}
};

helpers.StripSecrets(a)
