local kube = import "kube.jsonnet";

{
  urlrelease(config, group):: kube.kubeobj('tidepool/v1beta1', 'URLRelease', group.name) {
    url: group.urlrelease.url,
  },
}