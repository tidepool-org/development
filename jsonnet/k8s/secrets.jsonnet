local secrets = import 'secrets.k8s.jsonnet.TEMPLATE';

function(config) {
  apiVersion: "v1",
  kind: "List",
  items: secrets(config)
}
