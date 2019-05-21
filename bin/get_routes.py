#!/usr/local/bin/python3
# sets DNS entries for all virtualhosts served by Ambassador in the current K8s cluster
import os
import subprocess
import sys
import json
import tempfile

BASE_STRING = """
    {
        "Action": "UPSERT",
        "ResourceRecordSet": {
            "Name": "qa1-app.tidepool.org",
            "Type": "A",
            "AliasTarget": {
                "DNSName": "",
                "EvaluateTargetHealth": false 
            }
        }
    }
"""

hostedZoneId="Z2895YZY6K7CA5" #corresponds to tidepool.org
aliasHostedZoneId="Z18D5FSROUN65G"

elb=subprocess.check_output(["identify_loadbalancers"]).decode('utf-8').strip()
hosts=subprocess.check_output(["./virtual_hosts"]).decode('utf-8').strip().split('\n')

changes = list()
for virtual_host in hosts:
    change = json.loads(BASE_STRING)
    change["ResourceRecordSet"]["Name"] = virtual_host
    change["ResourceRecordSet"]["AliasTarget"]["HostedZoneId"] = aliasHostedZoneId
    change["ResourceRecordSet"]["AliasTarget"]["DNSName"] = elb
    changes.append(change)

changeset = dict()
changeset["Changes"] = changes
print(json.dumps(changeset, indent=4, sort_keys=True))


