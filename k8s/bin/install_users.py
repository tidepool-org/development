#!/usr/local/bin/python3
# adds Tidepool ops members as system:masters of current cluster

import subprocess
import json

USERS="- userarn: arn:aws:iam::118346523422:user/lennartgoedhart-cli\n  username: lennartgoedhart-cli\n  groups:\n    - system:masters\n- userarn: arn:aws:iam::118346523422:user/benderr-cli\n  username: benderr-cli\n  groups:\n    - system:masters\n- userarn: arn:aws:iam::118346523422:user/derrick-cli\n  username: derrick-cli\n  groups:\n    - system:masters\n- userarn: arn:aws:iam::118346523422:user/mikeallgeier-cli\n  username: mikeallgeier-cli\n  groups:\n    - system:masters\n"

cm=subprocess.check_output(["kubectl", "get", "configmap", "-n", "kube-system", "aws-auth", "-o", "json"])
configmap=json.loads(cm)
configmap["data"]["mapUsers"]=USERS

out=json.dumps(configmap)
process = subprocess.Popen(["kubectl", "apply", "-f", "-"], stdin=subprocess.PIPE, stdout=subprocess.PIPE)
process.stdin.write(out.encode("utf-8"))
print(process.communicate()[0])

