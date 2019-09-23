FROM ubuntu:18.04 
ENV TERM xterm-256color
ENV TZ America/Los_Angeles
ENV DEBIAN_FRONTEND noninteractive
RUN apt update && apt upgrade && \
    apt install nano wget python3-pip curl git openjdk-8-jdk vim python3 build-essential file locales jq expect -y && \
    pip3 install --upgrade --user awscli boto3
RUN locale-gen en_US.UTF-8
RUN wget https://github.com/databricks/sjsonnet/releases/download/0.1.6/sjsonnet.jar -O sjsonnet.jar && \
    chmod 755 sjsonnet.jar && \
    mv sjsonnet.jar /usr/local/bin && \
    ln -s /usr/local/bin/sjsonnet.jar /usr/local/bin/jsonnet
RUN wget https://raw.githubusercontent.com/helm/helm/master/scripts/get -O get_helm.sh && \
    bash get_helm.sh && \
    rm get_helm.sh
RUN curl --silent --location "https://github.com/weaveworks/eksctl/releases/download/latest_release/eksctl_$(uname -s)_amd64.tar.gz" | tar xz -C /tmp && \
    mv /tmp/eksctl /usr/local/bin
RUN curl -LO https://storage.googleapis.com/kubernetes-release/release/`curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt`/bin/linux/amd64/kubectl && \
    chmod +x ./kubectl && \
    mv ./kubectl /usr/local/bin/kubectl
RUN git clone https://github.com/ahmetb/kubectx /opt/kubectx && \
    mv /opt/kubectx/kubectx /usr/local/bin/kubectx && \
    mv /opt/kubectx/kubens /usr/local/bin/kubens && \
    rm -rf /opt/kubectx
RUN wget https://github.com/mikefarah/yq/releases/download/2.4.0/yq_linux_amd64 -O yq && \
    chmod 755 yq && \
    mv yq /usr/local/bin/yq
RUN curl -o aws-iam-authenticator https://amazon-eks.s3-us-west-2.amazonaws.com/1.14.6/2019-08-22/bin/linux/amd64/aws-iam-authenticator && \
    curl -o aws-iam-authenticator.sha256 https://amazon-eks.s3-us-west-2.amazonaws.com/1.14.6/2019-08-22/bin/linux/amd64/aws-iam-authenticator.sha256 && \
    openssl sha1 -sha256 aws-iam-authenticator && \
    chmod +x ./aws-iam-authenticator && \
    rm ./aws-iam-authenticator.sha256 && \
    mv aws-iam-authenticator /usr/local/bin/aws-iam-authenticator
RUN wget https://github.com/github/hub/releases/download/v2.11.2/hub-linux-amd64-2.11.2.tgz -O - | gunzip |  tar xv -C /tmp/ && \
    mv /tmp/hub-linux-amd64-2.11.2/bin/hub . && \
    chgrp root hub && \
    chown root hub && \
    mv hub /usr/local/bin
RUN wget https://github.com/fluxcd/flux/releases/download/1.14.2/fluxctl_linux_amd64 -O fluxctl && \
    mv fluxctl /usr/local/bin && \
    chmod 755 /usr/local/bin/fluxctl
RUN curl -s -L -o /usr/local/bin/cfssl https://pkg.cfssl.org/R1.2/cfssl_linux-amd64 && \
    curl -s -L -o /usr/local/bin/cfssljson https://pkg.cfssl.org/R1.2/cfssljson_linux-amd64 && \
    curl -s -L -o /usr/local/bin/cfssl-certinfo https://pkg.cfssl.org/R1.2/cfssl-certinfo_linux-amd64 && \
    chmod +x /usr/local/bin/cfssl*
RUN mv ~/.local/bin/* /usr/local/bin
RUN wget https://github.com/derailed/k9s/releases/download/0.8.4/k9s_0.8.4_Linux_x86_64.tar.gz -O -| gunzip | tar xv -C /tmp && \
    mv /tmp/k9s /usr/local/bin && \
    chmod 755 /usr/local/bin/k9s
COPY tpctl.sh /root/tpctl
CMD [ "/root/tpctl"  ]
