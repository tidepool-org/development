local helpers = import 'helpers.jsonnet';

local Helmrelease(config, service) = helpers.helmrelease(config, 'prometheusOperator', service) {
  local thanos = config.services.thanos,

  spec+: {
    chart: {
      repository: 'https://kubernetes-charts.storage.googleapis.com/',
      name: 'prometheus-operator',
      version: '5.13.0',
    },
    values+: {
      prometheus: {
        prometheusSpec: {
          replicas: service.values.prometheus.replicaCount,  // work in High-Availability mode
          retention: service.values.prometheus.retention,  // we only need a few hours of retention, since the rest is uploaded to blob
          image: {
            tag: 'v2.8.0',  // use a specific version of Prometheus
          },
          externalLabels: {  // a cool way to add default labels to all metrics
            geo: 'us',
            region: config.cluster.eks.region,
          },
          serviceMonitorNamespaceSelector: {  // allows the operator to find target config from multiple namespaces
            any: true,
          },
          thanos: {  // add Thanos Sidecar
            tag: thanos.deployment.tag,  // a specific version of Thanos
            objectStorageConfig: {  // blob storage configuration to upload metrics
              key: 'thanos.yaml',
              name: thanos.secret.name,
            },
          },
        },
      },
      grafana: {  // (optional) we don't need Grafana in all clusters
        enabled: false,
      },
    },
  },
};

local Secret(config, service) = helpers.secret(config, 'thanos', service) {
  data_+:: {
    'thanos.yaml': {
      type: 'S3',
      config: {
        bucket: service.secret.values.bucket,
        endpoint: 's3.%s.amazonaws.com' % config.cluster.eks.region,
        region: config.cluster.eks.region,
        insecure: false,
        signature_version2: false,
        encrypt_sse: false,
        put_user_metadata: {},
        http_config: {
          idle_conn_timeout: '0s',
          response_header_timeout: '0s',
          insecure_skip_verify: false,
        },
        trace: {
          enable: false,
        },
      },
    },
  },
};

function(config) {
  local service = config.services.prometheusOperator,
  Helmrelease: if service.helmrelease.create then Helmrelease(config, service),
  Namespace: if service.namespace.create then helpers.namespace(config, 'prometheusOperator', service),
  //ThanosSecret: Secret(config, service), // XXX
}
