#local config=std.extVar("CONFIG_DATA");
#local kind  = std.extVar("KIND");
#local protocol = std.extVar("PROTOCOL");

local kind = "internal";
local protocol = "http";
local config=[];

local VIRTUAL_HOST_KEY = '{{ $legalName }}';

# The host served by the API Gateway
local HOST='{{ if ne $port $default -}}{{- printf "%s:%s" $dnsName $port -}} {{- else -}} {{ printf " %s" $dnsName -}}{{- end -}}';

# The name used for SNI
local EXTERNAL_HOST_NAME = '{{ $dnsName }}';

# The name of the TLS secret containing the TLS cert
local TLS_SECRET_NAME = '{{ include "charts.certificate.secretName" . }}';

# The namespace of the TLS secret containing the TLS cert
local TLS_SECRET_NAMESPACE = '{{ $.Release.Namespace }}';

# The name of the Gateway Proxy Service
local GATEWAY_PROXY_NAME = '{{ $.Value.globals.proxy.name }}';

# The namespace of the Gateway Proxy Service
local GATEWAY_PROXY_NAMESPACE = '{{ $.Values.global.proxy.namespace }}';

# The environment being instantiated
local ENVIRONMENT = '{{ $.Release.Namespace }}';

# The name used to access the virtual service from other services
local INTERNAL_VS_NAME = 'internal';

# The name used to access the virtual service from the LoadBalancer.
local EXTERNAL_VS_NAME = ENVIRONMENT + "-external";


# These are the Kubernetes API versions for solo.io resources
local GATEWAY_API_VERSION = 'gateway.solo.io/v1';
local GLOO_API_VERSION = 'gloo.solo.io/v1';

local CORS_POLICY = 
{
    allowCredentials: true,
    allowHeaders: [
        "authorization",
        "content-type",
        "x-tidepool-session-token",
        "x-tidepool-trace-request",
        "x-tidepool-trace-session"
    ],
    allowMethods: [
        "GET",
        "POST",
        "PUT",
        "PATCH",
        "DELETE",
        "OPTIONS"
    ],
    allowOriginRegex: [
        ".*"
    ],
    exposeHeaders: [
        "x-tidepool-session-token",
        "x-tidepool-trace-request",
        "x-tidepool-trace-session"
    ],
    maxAge: "600s"
};

local metadata_spec(name, namespace) = {
    name: name,
    namespace:  namespace
};

local VirtualService(routes, name, cors, protocol, hosts_served) = {
    useSSL:: protocol == "https",

    virtual_service: if routes then {
	    apiVersion: GATEWAY_API_VERSION,
        kind: "VirtualService",
        metadata: metadata_spec(name, ENVIRONMENT),
        spec: {
            sslConfig: if self.useSSL then {
    		    sniDomains: [ EXTERNAL_HOST_NAME ],
    		    secretRef: metadata_spec(TLS_SECRET_NAME, TLS_SECRET_NAMESPACE)
            },

            virtualHost: {
                domains: hosts_served,
                routes: routes,
                corsPolicy: cors
            },
            displayName: name
        }
    }
};

local Upstream(ref) = {
    apiVersion: GLOO_API_VERSION,
    kind: "Upstream",
    metadata: metadata_spec(ENVIRONMENT + "-" + ref.service + "-" + ref.port, ENVIRONMENT),
    spec: {     
	upstreamSpec: {
            kube : {
     		serviceName: ref.service,
     		serviceNamespace: ENVIRONMENT,
     		servicePort: ref.port
            }
        }
    }
};

local ExternalNameService() = {
    apiVersion: "v1",
    kind: "Service",
    metadata:  metadata_spec(INTERNAL_VS_NAME, ENVIRONMENT),
    spec:  {
        type: "ExternalName",
        externalName: GATEWAY_PROXY_NAME + "." + GATEWAY_PROXY_NAMESPACE + ".svc.cluster.local",
        ports: [ { port: 80 } ]
    }
};

local Gateway(useSSL) = {
    apiVersion: GATEWAY_API_VERSION,
    kind: "Gateway",
    metadata: metadata_spec(if useSSL then "gateway-ssl"  else "gateway", GATEWAY_PROXY_NAMESPACE),
    bindAddress: '::',
    ssl: useSSL,
    useProxyProto: false, 
    bindPort: if useSSL then  8443 else 8080
};

local GatewayProxyService(service_type, useSSL) = {
    apiVersion: "v1",
    kind:  "Service",
    metadata:  
        metadata_spec(GATEWAY_PROXY_NAME + if useSSL then "-ssl" else "", GATEWAY_PROXY_NAMESPACE) +
        { 
            labels: { 
                app : "gloo", 
                gloo: GATEWAY_PROXY_NAME 
            } 
        },
    spec:  {
        ports:  {
            protocol: "TCP" 
        } + if useSSL then {
            name: "https",
            port: 443,
            targetPort: 8443
        } else {
            name: "http",
            port: 80,
            targetPort: 8080
        },
        selector: { gloo: GATEWAY_PROXY_NAME }
    } + if service_type == "elb" then {
        externalTrafficPolicy:  "Local",
        type:  "LoadBalancer"
    } else if service_type == "nlb" then {
        externalTrafficPolic: "Local",
        type:  "LoadBalancer",
        annotations:  {
            "service.beta.kubernetes.io/aws-load-balancer-type": "nlb"
        }
    } else if service_type == "cluster" then {
        type: "ClusterIP"
    } else error 'Bad service type'
};

local service_and_port(mapping) = {
    local indices = std.findSubstr(":", mapping.service ),
    local parts = 
        if std.length(indices) == 1 
        then std.split(":") 
        else [ mapping.service, "80" ],
    service: std.strReplace(parts[0], ".default", ""),
    port: std.parseInt(parts[1])
};

local service_name(manifest) = 
    std.strReplace(
        std.strReplace( manifest.metadata.name, ENVIRONMENT + "-", ""),
        INTERNAL_VS_NAME, 
        "internal");

local ManifestsDict(manifest) = {
    ["gloo-" + service_name(manifest) + "-" + std.asciiLower(manifest.kind)] : manifest
};

local Route(mapping) = {
    local found = 'rewrite' in mapping,
    routePlugins: if found then {
        prefixRewrite: { prefixRewrite: ("/") }
    } else if mapping.rewrite != "" then {
        prefixRewrite: { prefixRewrite : mapping.rewrite }
    } else {
    },

    matcher: {
        methods: 
            if 'method_regex' in mapping && mapping.method_regex
            then std.split(mapping.method, "|")
            else [ mapping.method ]
    } + if 'prefix_regex' in mapping && mapping.prefix_regex then {
        regex: mapping.prefix
    } else if 'prefix' in mapping && mapping.prefix then {
        prefix: mapping.prefix
    },
    
    routeAction: {
        local svc_port = service_and_port(mapping),
        single: {
            upstream: metadata_spec(ENVIRONMENT + "-" + svc_port.service + "-" + std.toString(svc_port.port), ENVIRONMENT)
        }
    }
};


local withKey(route) = route + {
    local matcher = route["matcher"],
    key:: 
        if "regex" in matcher then
            std.length(matcher["regex"])
        else if "prefix" in matcher then
            std.length(matcher["prefix"])
        else if "exact" in matcher then
            std.length(matcher["exact"])
        else
            0
};

local fold_func(x,y) = x + ManifestsDict(y);

local ordered(routes) = 
    std.sort([ withKey(route) for route in routes ], function(x) -x.key);

local sortedRoutes(mappings) = ordered([ Route(mapping) for mapping in mappings]);

local sorted = sortedRoutes(config);

if std.length(sorted) > 0 then
    if kind == "internal" then
        std.foldl(fold_func, 
            [ Upstream(service_and_port(mapping)) for mapping in config ], 
             ManifestsDict(VirtualService(sorted, INTERNAL_VS_NAME, null, "http", [ INTERNAL_VS_NAME + "." + ENVIRONMENT])) )
    else if protocol == "https" then
            ManifestsDict(VirtualService(sorted, VIRTUAL_HOST_KEY, CORS_POLICY, "https", [HOST]))
    else
            ManifestsDict(VirtualService(sorted, VIRTUAL_HOST_KEY, null, "http", [HOST]))
else 
    {}