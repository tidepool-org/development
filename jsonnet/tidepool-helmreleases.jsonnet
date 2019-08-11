local config=std.extVar("CONFIG_DATA");

local svcs = [ 
  "auth", "blip", "blob", "data", "export", "gatekeeper", "highwater", "hydrophone",
  "image", "jellyfish", "messageapi", "migrations", "notification", "seagull", "shoreline",
  "task", "tidewhisperer", "tools", "user" ];

local stripSecrets(obj) = 
{ [k]: obj[k] for k in std.objectFields(obj) if k != "secret" && ! std.isObject(obj[k]) } +
{ [k]: stripSecrets(obj[k]) for k in std.objectFields(obj) if k != "secret" && std.isObject(obj[k]) };

local toEnvironment(name, environment) = {
  kind: "HelmRelease",
  apiVersion: "flux.weave.works/v1beta1",
  metadata: {
    name: "tidepool",
    namespace: name,
    annotations: {
      ['flux.weave.works/tag.'+k]: ("glob:" + environment.gitops.branch + "-*") for k in svcs
    }
  },
  spec: {
    releaseName: name + "-tidepool",
    chart: {
      git: "git@github.com:tidepool-org/development",
      path: "charts/tidepool/0.1.7",
      ref: "k8s"
    },
    values: {
      global: {
        fullnameOverride: "",
        nameOverride: "",
        cluster: {
          region: config.cluster.eks.region,
          name: config.cluster.eks.name,
          mesh: config.cluster.mesh,
          gateway: config.cluster.gateway,
          logLevel: config.cluster.logLevel,
        },
      } + environment.global
    } + environment.sharedInternalSecrets 
      + environment.tidepoolServices
      + environment.thirdPartyInternalServices
      + environment.externallySharedSecrets
  }
};

local helmreleases=std.prune(std.mapWithKey(toEnvironment, config.environments));

{
  [k+"-helmrelease.json"] : helmreleases[k] for k in std.objectFields(helmreleases)
}
