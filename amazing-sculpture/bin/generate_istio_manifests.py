#!/usr/local/bin/python3
import os
import subprocess
import sys
import json
import yaml

GATEWAY="primary-gateway"
CHARTSDIR="/Users/derrickburns/go/src/github.com/tidepool-org/development/charts/"
HEADER="{{- if .Values.istio.enabled -}}\n"
FOOTER="{{- end -}}\n"

CORS_POLICY_STRING = """
{
    "allowCredentials": true,
    "allowHeaders": [
        "authorization",
        "content-type",
        "x-tidepool-session-token",
        "x-tidepool-trace-request",
        "x-tidepool-trace-session"
    ],
    "allowMethods": [
        "GET",
        "POST",
        "PUT",
        "PATCH",
        "DELETE",
        "OPTIONS"
    ],
    "allowOrigin": [
        "*"
    ],
    "exposeHeaders": [
        "x-tidepool-session-token",
        "x-tidepool-trace-request",
        "x-tidepool-trace-session"
    ],
    "maxAge": "300s"
}
"""
CORS_POLICY=json.loads(CORS_POLICY_STRING)

def ambassador_services_from(docs):
    """Return the services from a set of K8s Manifests."""
    services = []
    for doc in docs:
        if doc is not None:
            for k,v in doc.items():
                if k == "kind" and v == "Service":
                    services.append(doc)
    return services

def istio_http_routes_from_services(services):
    """Return the Istio http routes from a set of Services with Ambassador annotations."""
    http_routes_dict = dict()
    for service in services:
        ambassador_metadata = metadata_from_ambassador_service(service)
        if ambassador_metadata:
            docs = yaml_docs_from_metadata_string(ambassador_metadata)
            name = ambassador_metadata["name"]
            dest = dest_from_name(name)
            istio_http_routes_from_ambassador_docs(http_routes_dict, docs, dest)
    return http_routes_dict

def write_manifest(dir, manifest, name):
    """Write a single file containing Istio manifests."""
    filename = dir + "/" + "istio-" + name + ".yaml"
    with open(filename, 'w') as outfile:
        outfile.write(HEADER)
        yaml.dump(manifest, outfile, default_flow_style=False)
        outfile.write(FOOTER)

def metadata_from_ambassador_service(service):
    """Return the metadata from object or None if it does not exist."""
    if "metadata" in service:
        metadata=service["metadata"]
        return metadata
    else:
        return None

def name_from_metadata(metadata):
    """Return the name from object or None if it does not exist."""
    if "name" in metadata:
        return metadata["name"]
    else:
        return None

def annotation_from_metadata(metadata):
    """Return the Ambassador annotation string from a document."""
    if "annotations" in metadata and metadata["annotations"]:
        annotations = metadata["annotations"]
        if "getambassador.io/config" in annotations:
            return annotations["getambassador.io/config"]
        else:
            return None
    else:
        return None

def sort_key(http_route):
    uri = http_route["match"][0]["uri"]
    if "regex" in uri:
        return len(uri["regex"])
    elif "prefix" in uri:
        return len(uri["prefix"])
    elif "exact" in uri:
        return len(uri["exact"])
    else:
        return 0

def ordered_http_routes(http_routes):
    """TBB. Return a sorted list of http routes from least general to most general."""
    # sort by length of prefix/regex from longest to 
    return sorted(http_routes, key=sort_key, reverse=True) 

def virtual_service_basename(host):
    """Return the Istio virtual service name."""
    return host.replace("default-", "").replace(".tidepool.org", "")

def local_name(base):
    """Return the Istio virtual service name."""
    return base + ".{{- .Release.Namespace -}}." + "svc.cluster.local"    

def virtual_service_filename(base):
    """Return the Istio virtual service name."""
    return base + "-virtual-service.yaml"

def virtual_service_from_http_routes(gateway, ordered, base):
    """Return a virtual service object from a gateway, list of HTTPRoutes, and Istio virtual service name."""
    vsname = local_name(base)
    if len(ordered) > 0:
        virtual_service = dict()
        virtual_service["apiVersion"] = "networking.istio.io/v1alpha3"
        virtual_service["kind"] = "VirtualService"
        virtual_service["metadata"] = dict()
        virtual_service["metadata"]
        virtual_service["metadata"]["name"] = vsname
        virtual_service["metadata"]["namespace"] = "{{- .Release.Namespace -}}"
        virtual_service["spec"] = dict()
        virtual_service["spec"]["hosts"] = list()
        virtual_service["spec"]["hosts"].append("{{- .Release.Namespace -}}-" + base + ".tidepool.org")
        virtual_service["spec"]["hosts"].append(local_name("internal-" + base))
        gateways = list()
        gateways.append(gateway)
        gateways.append("mesh")
        virtual_service["spec"]["gateways"] = gateways
        virtual_service["spec"]["http"] = ordered
        return virtual_service
    else:
        return None

def dest_from_name(name):
    """Return the target host for a routing rule."""
    return name + ".{{- .Release.Namespace -}}." + "svc.cluster.local"

def yaml_docs_from_metadata_string(metadata):
    """Return a list of YAML objects from a YAML string."""
    annotation_string = annotation_from_metadata(metadata)
    if annotation_string is None:
        return None
    docs = list()
    for raw_doc in annotation_string.split('\n---'):
        try:
            docs.append(yaml.load(raw_doc))
        except SyntaxError:
            docs.append(raw_doc)
    return docs

def istio_http_routes_from_ambassador_docs(http_routes_dict, docs, dest):
    """Return the HTTPRoute(s) from an Ambasaddor doc."""
    if docs and len(docs) > 0:
        for doc in docs:
            if doc["kind"] != "Mapping":
                continue
            http_route = dict()

            match = dict()
            match["uri"] = dict()
            if "prefix_regex" in doc and doc[ "prefix_regex"]:
                match["uri"]["regex"] = doc["prefix"]
            elif "prefix" in doc and doc["prefix"]:
                match["uri"]["prefix"] = doc["prefix"]
            else:
                print("no prefix in", doc)

            match["method"] = dict()
            if "method_regex" in doc and doc[ "method_regex"]:
                match["method"]["regex"] = doc["method"]
            else:
                match["method"]["exact"] = doc["method"]
            http_route["match"] = list()
            http_route["match"].append(match)

            if "rewrite" not in doc:
                http_route["rewrite"] = dict()
                http_route["rewrite"]["uri"] = "/"
            elif doc["rewrite"] != "":
                http_route["rewrite"] = dict()
                http_route["rewrite"]["uri"] = doc["rewrite"]

            if "service" in doc:
                s = doc["service"]
                if ":" in s:
                    (host,port) = s.split(":")
                else:
                    host = s
                    port = 80
                routes = list()
                route = dict()
                route["destination"] = dict()
                route["destination"]["port"] = dict()
                route["destination"]["port"]["number"] = int(port)
                route["destination"]["host"] = dest
                routes.append(route)
                http_route["route"] = routes
                http_route["corsPolicy"] = CORS_POLICY

            if http_route["match"]:
                host = doc["host"]
                if host not in http_routes_dict:
                    http_routes_dict[host] = list()
                http_routes = http_routes_dict[host]
                http_routes.append( http_route )
    return http_routes_dict

def create_istio_gateway(hosts):
    """Create a gateway spec"""
    gateway = dict()
    gateway["apiVersion"] = "networking.istio.io/v1alpha3"
    gateway["kind"] = "Gateway"
    gateway["metadata"] = dict()
    gateway["metadata"]["name"] = "primary-gateway"
    gateway["metadata"]["namespace"] = "{{.Release.Namespace}}"
    gateway["spec"] = dict()
    gateway["spec"]["selector"] = dict()
    gateway["spec"]["selector"]["istio"] = "ingressgateway"
    servers = list()
    server = dict()
    server["port"] = dict()
    server["port"]["number"] = 443
    server["port"]["name"] = "https-443"
    server["port"]["protocol"] = "HTTPS"
    server["hosts"] = list()
    for r in hosts:
        host = r.replace("default", "{{- .Release.Namespace -}}")
        server["hosts"].append(host)
    server["tls"] = dict()
    server["tls"]["mode"] = "SIMPLE"
    server["tls"]["credentialName"] = "tidepool-org"
    servers.append(server)
    gateway["spec"]["servers"] = servers
    return gateway


"""
Example virtual service output:
{{ if .Values.istio.gateway.enabled }}
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: app.{{- .Release.Namespace -}}.svc.cluster.local
  namespace: '{{- .Release.Namespace -}}'
spec:
  gateways:
  - primary-gateway
  hosts:
  - '{{- .Release.Namespace -}}-app.tidepool.org'
  http:
  - corsPolicy:
      allowCredentials: true
      allowHeaders:
      - authorization
      - content-type
      - x-tidepool-session-token
      - x-tidepool-trace-request
      - x-tidepool-trace-session
      allowMethods:
      - GET
      - POST
      - PUT
      - PATCH
      - DELETE
      - OPTIONS
      allowOrigin:
      - '*'
      exposeHeaders:
      - x-tidepool-session-token
      - x-tidepool-trace-request
      - x-tidepool-trace-session
      maxAge: 300s
    match:
    - method:
        regex: GET|OPTIONS|POST|PUT|PATCH|DELETE
      uri:
        prefix: /
    route:
    - destination:
        host: blip.{{- .Release.Namespace -}}.svc.cluster.local
---
apiVersion: networking.istio.io/v1alpha3
kind: Gateway
metadata:
  name: primary-gateway
  namespace: {{.Release.Namespace}}
spec:
  selector:
    istio: ingressgateway
  servers:
  - port:
      number: 443
      name: https-443
      protocol: HTTPS
    hosts:
    - "{{- .Release.Namespace -}}-app.tidepool.org"
    - "{{- .Release.Namespace -}}-api.tidepool.org"
    - "{{- .Release.Namespace -}}-uploads.tidepool.org"
    tls:
      mode: SIMPLE
      serverCertificate: /etc/istio/ingressgateway-certs/tls.crt
      privateKey: /etc/istio/ingressgateway-certs/tls.key
{{ end }}
"""


input_dir=CHARTSDIR + 'tidepool/0.4.1'
output_dir=CHARTSDIR + 'tidepool/0.4.1/templates/'
helm = subprocess.Popen(['helm', 'template', input_dir], stdout=subprocess.PIPE)
docs = yaml.load_all(helm.stdout)
ambassador_services = ambassador_services_from(docs)
istio_http_routes_dict = istio_http_routes_from_services(ambassador_services)
for host,istio_http_routes in istio_http_routes_dict.items():
    ordered_routes = ordered_http_routes(istio_http_routes)
    base = virtual_service_basename(host)
    virtual_service = virtual_service_from_http_routes(GATEWAY, ordered_routes, base)
    write_manifest(output_dir, virtual_service, base + "-virtual-service")
gateway = create_istio_gateway(istio_http_routes_dict.keys())
write_manifest(output_dir, gateway, "gateway")
