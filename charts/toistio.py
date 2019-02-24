#!/usr/local/bin/python3
import yaml
import os

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
    metadata=service["metadata"]
    print("processing", metadata["name"])
    if "getambassador.io/config" in metadata:
        annotation=metadata["getambassador.io/config"]
        print(annotation)
    else:
        print(metadata.keys())


stream = open("all", "r")
docs = yaml.load_all(stream)
services = services_from(docs)
process_services(services)
