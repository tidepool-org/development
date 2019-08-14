local helpers = import 'helpers.jsonnet';

local Secret(config, service) = helpers.secret(config, service) {
  data_+:: {
    'thanos.yaml': {
      type: 'S3',
      config: std.manifestYamlDoc ({
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
      }),
    },
  },
};

function(config) {
  local service = config.services.thanos { name: 'thanos' },
  Secret: Secret(config, service), 
}
