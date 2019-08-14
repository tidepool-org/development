local helpers = import 'helpers.jsonnet';

local Helmrelease(config, service) = helpers.helmrelease(config, service) {
  spec+: {
    chart: {
      repository: 'https://kubernetes-charts.storage.googleapis.com/',
      name: 'kiam',
      version: '2.3.0',
    },
    values+: {
      agent: {
        image: {
          tag: 'd999e61e28befb872cd1875812c9d1bf37dc4f37',
        },
        enabled: true,
        host: {
          iptables: true,
          interface: '!eth0',
        },
        // The default chart timeout is too small. See https://github.com/uswitch/kiam/issues/94#issuecomment-423876602
        gatewayTimeoutCreation: '1s',

        // If you only want the agents to run on some nodes, you can set this value. In our example,
        // this isn't necessary, and the agents won't run on the kiam-server boxes as they are tainted
        // to prevent any other pods running.
        // nodeSelector:
        //   kiam-agent: "true"
        //

        extraHostPathMounts: [
          {
            name: 'ssl-certs',
            mountPath: '/etc/ssl/certs',
            hostPath: '/etc/pki/ca-trust/extracted/pem',
            readOnly: true,
          },
        ],
        log: {
          level: config.cluster.logLevel,
        },

        server: {
          image: {
            tag: 'd999e61e28befb872cd1875812c9d1bf37dc4f37',
          },
          enabled: true,
          // This is to choose a different node for agent vs server. Without it, the kiam-server pods
          // would be scheduled on all nodes, including the ones that are running the kiam-agents
          nodeSelector: {
            'kiam-server': 'true',
          },
          // This states that the server pods can withstand the taint on the second node group that prevents
          // other pods from being scheduled there.
          tolerations: [
            {
              key: 'kiam-server',
              operator: 'Equal',
              value: 'false',
              effect: 'NoExecute',
            },
          ],
          extraHostPathMounts: [
            {
              name: 'ssl-certs',
              mountPath: '/etc/ssl/certs',
              hostPath: '/etc/pki/ca-trust/extracted/pem',
              readOnly: true,
            },
          ],
          extraArgs: {
            region: config.cluster.eks.region,
            'assume-role-arn': '%s-kiam-server-role' % config.cluster.eks.name,
          },
          useHostNetwork: true,
          log: {
            level: config.cluster.logLevel,
          },
        },
      },
    },
  },
};

function(config) {
  local service = config.services.kiam { name: 'kiam' },
  Helmrelease: if service.helmrelease.create then Helmrelease(config, service),
  Namespace: if service.namespace.create then helpers.namespace(config, service),
}
