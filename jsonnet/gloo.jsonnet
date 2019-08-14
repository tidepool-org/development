local helpers = import 'helpers.jsonnet';

local Helmrelease(config, group) =
  helpers.helmrelease(config, group) {
    spec+: {
      chart: {
        repository: 'https://storage.googleapis.com/solo-public-helm/',
        name: 'gloo',
        version: '0.18.12',
      },
      values+: {
        crds: {
          create: group.crds.create,
        },
        settings: {
          create: true,
        },
        discovery: {
          fdsMode: 'WHITELIST',
        },
        gatewayProxies: {
          gatewayProxyV2: {
            group: {
              extraAnnotations: {
                'group.beta.kubernetes.io/aws-load-balancer-type': 'nlb',
                'external-dns.alpha.kubernetes.io/alias': true,
                'external-dns.alpha.kubernetes.io/hostname': std.join(',', group.gatewayProxy.hostnames),
                'group.beta.kubernetes.io/aws-load-balancer-additional-resource-tags': 'cluster:' + config.cluster.eks.name,
              },
            },
          },
        },
      },
    },
  };

local Gateway(config, group) = {
  apiVersion: 'gateway.solo.io.v2/v2',
  kind: 'Gateway',
  metadata: {
    annotations: {
      origin: 'default',
    },
    name: 'gateway-ssl',
    namespace: group.namespace.name,
  },
  spec: {
    ssl: true,
    bindAddress: '::',
    bindPort: 8443,
    gatewayProxyName: 'gateway-proxy-v2',
    httpGateway: {},
    useProxyProto: false,
    plugins: {
      accessLoggingService: {
        accessLog: [
          {
            fileSink: {
              path: '/dev/stdout',
              jsonFormat: {
                startTime: '%START_TIME(%Y/%m/%dT%H:%M:%S%z %s)%',
                duration: '%DURATION%',
                protocol: '%PROTOCOL%',
                method: '%REQ(:METHOD)%',
                authority: '%REQ(:AUTHORITY)%',
                path: '%REQ(X-ENVOY-ORIGINAL-PATH?:PATH)%',
                bytesReceived: '%BYTES_RECEIVED%',
                bytesSent: '%BYTES_SENT%',
                responseCode: '%RESPONSE_CODE%',
                sessionToken: '%REQ(x-tidepool-session-token)%',
              },
            },
          },
        ],
      },
    },
  },
};

function(config) {
  local group = config.groups.gloo { name: 'gloo' },
  Helmrelease: if group.helmrelease.create then Helmrelease(config, group),
  Namespace: if group.namespace.create then helpers.namespace(config, group),
  Gateway: if group.gateway.create then Gateway(config, group),
}
