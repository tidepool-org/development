#!/usr/local/bin/python3
import yaml
import os

GATEWAY="primary-gateway"

def services_from(docs):
    services = []
    for doc in docs:
        if doc is not None:
            for k,v in doc.items():
                if k == "kind" and v == "Service":
                    services.append(doc)
    return services

def process_services(services):
    for service in services:
        process_service(service);

def process_service(service):
    vs = virtual_service_from_service(service)
    metadata = metadata_from_service(service)
    name = name_from_metadata(metadata)
    if vs is not None:
        with open( "/Users/derrickburns/go/src/github.com/tidepool-org/dev-ops/charts/istio/"
 + name + '-virtual-service.yaml', 'w') as outfile:
            yaml.dump(vs, outfile, default_flow_style=False)

def metadata_from_service(service):
    if "metadata" in service:
        metadata=service["metadata"]
        return metadata
    else:
        return None

def name_from_metadata(metadata):
    if "name" in metadata:
        return metadata["name"]
    else:
        return None

def annotation_from_metadata(metadata):
    if "annotations" in metadata:
        annotations = metadata["annotations"]
        if "getambassador.io/config" in annotations:
            annotation=annotations["getambassador.io/config"]

            return annotation
    else:
        return None

def virtual_service_from_service(service):
    metadata = metadata_from_service(service)
    name = name_from_metadata(metadata)
    dest = name + ".{{- .Values.namespace -}}." + "svc.cluster.local"
    annotation_string = annotation_from_metadata(metadata)
    docs = []
    if annotation_string is None:
        return None
    for raw_doc in annotation_string.split('\n---'):
        try:
            docs.append(yaml.load(raw_doc))
        except SyntaxError:
            docs.append(raw_doc)
    
    if len(docs) > 0:
        virtual_service = dict()
        virtual_service["apiVersion"] = "networking.istio.io/v1alpha3"
        virtual_service["kind"] = "VirtualService"
        virtual_service["metadata"] = dict()
        virtual_service["metadata"]
        virtual_service["metadata"]["name"] = name
        virtual_service["metadata"]["namespace"] = "{{ .Values.namespace }}"
        virtual_service["spec"] = dict()
        virtual_service["spec"]["hosts"] = list()
        virtual_service["spec"]["hosts"].append("{{ .Values.api.host }}")
        virtual_service["spec"]["hosts"].append("{{ .Values.externalapi.host }}")

        virtual_service["spec"]["http"] = list()
        virtual_service["spec"]["gateway"] = list()
        virtual_service["spec"]["gateway"].append(GATEWAY)
        for doc in docs:
            print(doc)
            combo = dict()

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
            combo["match"] = list()
            combo["match"].append(match)

            if "rewrite" in doc and doc["rewrite"] != "":
                combo["rewrite"] = dict()
                combo["rewrite"]["uri"] = doc["rewrite"]

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
                combo["route"] = route

            if combo["match"]:
                virtual_service["spec"]["http"].append( combo )

        if virtual_service["spec"]["http"]:
            return virtual_service
        else:
            return None
    else:
        return None

"""
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: bookinfo-rule
  namespace: {{.Values.namespace}}
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
        host: reviews.{{.Values.namespace}}.svc.cluster.local
  - match:
      uri:
        prefix: /reviews/
    rewrite:
      uri: "/x-reviews"   
    route:
    - destination:
        port:
          number: 9080 # can be omitted if its the only port for reviews
        host: reviews.{{.Values.namespace}}.svc.cluster.local
"""


stream = open("/Users/derrickburns/go/src/github.com/tidepool-org/dev-ops/charts/all", "r")
docs = yaml.load_all(stream)
services = services_from(docs)
process_services(services)
