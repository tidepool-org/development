#!/bin/bash
#
# Add ssh key to ssh-agent running in a Docker container.
# 
# Usage: $0 [${SSH_KEY:-id_rsa}]
#

SSH_KEY=${1:-id_rsa}
docker run -d --name=ssh-agent nardeas/ssh-agent
docker run --rm --volumes-from=ssh-agent -v ~/.ssh:/.ssh -it nardeas/ssh-agent ssh-add /root/.ssh/${SSH_KEY}

