#!/usr/local/bin/python3

import base64
import json
import os
import sys

import boto3
import yaml

file=sys.argv[1].strip()
if file.endswith('-secret.yaml'):
    base = os.path.basename(file[:-12])
elif file.endswith(".yaml"):
    base = os.path.basename(file[:-5])
else:
    print("bad filename ", file)
    exit()

f = open(file,"r")
input = f.read()
manifest = yaml.safe_load(input)
env=manifest["metadata"]["namespace"]
data=manifest["data"]

secret = dict()
secret["apiVersion"]= "kubernetes-client.io/v1"
secret["kind"] = "ExternalSecret"
secret["metadata"] = dict()
secret["metadata"]["name"] = base
secret["metadata"]["namespace"] = env
secret["secretDescriptor"] = dict()
secret["secretDescriptor"]["backendType"] = "secretsManager"
secret["secretDescriptor"]["data"] = list()

values = list() 

awsvalue = dict()

client = boto3.client('secretsmanager')
key=env + "/" + base 

for name,value in data.items():
    print(value)
    #decoded=base64.standard_b64decode(value).decode("utf-8") 
    decoded=value
    print(base, name,  decoded)
    value = dict()
    value["key"] = key
    value["name"] = name
    value["property"] = name
    awsvalue[value["name"]] = decoded
    values.append(value)

secret["secretDescriptor"]["data"] = values
print("processing file")
#print(yaml.dump(secret))
out=json.dumps(awsvalue)
#print(key, out)
client.create_secret( Name=key, SecretString=out)
#client.update_secret( SecretId=key, SecretString=out)
#client.delete_secret( SecretId=key)
