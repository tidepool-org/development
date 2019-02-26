#!/usr/local/bin/python3
import yaml
import os
import subprocess
import sys

GATEWAY="primary-gateway"
CHARTSDIR="/Users/derrickburns/go/src/github.com/tidepool-org/dev-ops/k8s/charts/"

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
    http_routes = list()
    for service in services:
        ambassador_metadata = metadata_from_ambassador_service(service)
        if ambassador_metadata:
            docs = yaml_docs_from_metadata_string(ambassador_metadata)
            name = ambassador_metadata["name"]
            dest = dest_from_name(name)
            http_routes.extend(istio_http_routes_from_ambassador_docs(docs, dest))
    return http_routes

def write_istio_virtual_service(vs, filename):
    """Write a file containing an Istio virtual service."""
    if vs is not None:
        with open(filename, 'w') as outfile:
            yaml.dump(vs, outfile, default_flow_style=False)
    else:
        print("no virtual service defined")

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
    if "annotations" in metadata:
        annotations = metadata["annotations"]
        if "getambassador.io/config" in annotations:
            return annotations["getambassador.io/config"]
    else:
        return None

def ordered_http_routes(http_routes):
    """TBB. Return a sorted list of http routes from least general to most general."""
    # sort by length of prefix/regex
    return http_routes

def virtual_service_name():
    """Return the Istio virtual service name."""
    return "backend" + ".{{- .Release.Namespace -}}." + "svc.cluster.local"    

def virtual_service_from_http_routes(gateway, ordered, vsname):
    """Return a virtual service object from a gateway, list of HTTPRoutes, and Istio virtual service name."""
    if len(ordered) > 0:
        virtual_service = dict()
        virtual_service["apiVersion"] = "networking.istio.io/v1alpha3"
        virtual_service["kind"] = "VirtualService"
        virtual_service["metadata"] = dict()
        virtual_service["metadata"]
        virtual_service["metadata"]["name"] = vsname
        virtual_service["metadata"]["namespace"] = "{{ .Release.Namespace }}"
        virtual_service["spec"] = dict()
        virtual_service["spec"]["hosts"] = list()
        virtual_service["spec"]["hosts"].append("\"*\"")

        virtual_service["spec"]["http"] = list()
        virtual_service["spec"]["gateway"] = list()
        virtual_service["spec"]["gateway"].append(GATEWAY)
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

def istio_http_routes_from_ambassador_docs(docs, dest):
    """Return the HTTPRoute(s) from an Ambasaddor doc."""
    http_routes = list()
    if len(docs) > 0:
        for doc in docs:
            print(doc)
            http_route = dict()

            match = dict()
            match["uri"] = dict()
            if "prefix_regex" in doc and doc[ "prefix_regex"]:
                match["uri"]["regex"] = doc["prefix"]
            else:
                match["uri"]["prefix"] = doc["prefix"]

            match["method"] = dict()
            if "method_regex" in doc and doc[ "method_regex"]:
                match["method"]["regex"] = doc["method"]
            else:
                match["method"]["exact"] = doc["method"]
            http_route["match"] = list()
            http_route["match"].append(match)

            if "rewrite" in doc and doc["rewrite"] != "":
                http_route["rewrite"] = dict()
                http_route["rewrite"]["uri"] = doc["rewrite"]

            if "service" in doc:
                s = doc["service"]
                if ":" in s:
                    (host,port) = s.split(":")
                else:
                    host = s
                    port = 80
                route = dict()
                route["destination"] = dict()
                route["destination"]["port"] = dict()
                route["destination"]["port"]["number"] = int(port)
                route["destination"]["host"] = dest
                http_route["route"] = route

            if http_route["match"]:
                http_routes.append( http_route )
    return http_routes

"""
Example output:

apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: bookinfo-rule
  namespace: {{.Release.Namespace}}
spec:
  hosts:
  - reviews.prod.svc.cluster.local
  - uk.bookinfo.com
  - eu.bookinfo.com
  gateways:
  - primary
  http:
  - match:
    - headers:
        cookie:
          user: dev-123
    rewrite:
      uri: "/dev-123-reviews"
    route:
    - destination:
        port:
          number: 7777
        host: reviews.{{.Release.Namespace}}.svc.cluster.local
  - match:
      uri:
        prefix: /reviews/
    rewrite:
      uri: "/x-reviews"   
    route:
    - destination:
        port:
          number: 9080 # can be omitted if its the only port for reviews
        host: reviews.{{.Release.Namespace}}.svc.cluster.local
"""
input_dir=CHARTSDIR + 'backend'
output_file=CHARTSDIR + 'router/templates/backend-virtual-service.yaml'
helm = subprocess.Popen(['helm', 'template', input_dir], stdout=subprocess.PIPE)
docs = yaml.load_all(helm.stdout)
ambassador_services = ambassador_services_from(docs)
istio_http_routes = istio_http_routes_from_services(ambassador_services)
ordered_http_routes = ordered_http_routes(istio_http_routes)
vsname = virtual_service_name()
virtual_service = virtual_service_from_http_routes(GATEWAY, ordered_http_routes, vsname)
write_istio_virtual_service(virtual_service, output_file)
