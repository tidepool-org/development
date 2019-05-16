#!/usr/local/bin/python3
# makes changes to DNS resource records 
import os
import subprocess
import sys
import json
import tempfile

input = subprocess.check_output(['get_routes.py']).decode('utf-8')
hostedZoneId="Z2895YZY6K7CA5" #corresponds to tidepool.org

# Open the file for writing.
with open(tmp.name, 'w') as f:
    f.write(input)
    f.flush()
    f.seek(0)
out = subprocess.check_output(['aws', 'route53', 'change-resource-record-sets',  '--hosted-zone-id', hostedZoneId, '--change-batch', 'file://' + tmp.name])
print(out)


