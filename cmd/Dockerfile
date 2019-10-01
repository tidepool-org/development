FROM ubuntu:18.04 
ENV TERM xterm-256color
ENV TZ America/Los_Angeles
ENV DEBIAN_FRONTEND noninteractive
RUN apt update -y && apt upgrade -y && \
    apt install nano python3-pip curl git openjdk-8-jdk vim python3 build-essential file locales jq expect -y && \
    pip3 install --upgrade --user awscli boto3 environs
RUN locale-gen en_US.UTF-8
RUN curl -sL https://github.com/google/jsonnet/releases/download/v0.14.0/jsonnet-bin-v0.14.0-linux.tar.gz | tar xz -C /tmp && \ 
    mv /tmp/jsonnet /usr/local/bin
RUN curl -sL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/master/scripts/get && \
    bash get_helm.sh && \
    rm get_helm.sh
RUN curl -sL "https://github.com/weaveworks/eksctl/releases/download/latest_release/eksctl_Linux_amd64.tar.gz" | tar xz -C /tmp && \
    mv /tmp/eksctl /usr/local/bin
RUN curl -sL -o /usr/local/bin/kubectl https://storage.googleapis.com/kubernetes-release/release/`curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt`/bin/linux/amd64/kubectl 
RUN git clone https://github.com/ahmetb/kubectx /opt/kubectx && \
    mv /opt/kubectx/kubectx /usr/local/bin/kubectx && \
    mv /opt/kubectx/kubens /usr/local/bin/kubens && \
    rm -rf /opt/kubectx
RUN curl -sL -o /usr/local/bin/yq https://github.com/mikefarah/yq/releases/download/2.4.0/yq_linux_amd64 
RUN curl -sL -o /usr/local/bin/aws-iam-authenticator https://amazon-eks.s3-us-west-2.amazonaws.com/1.14.6/2019-08-22/bin/linux/amd64/aws-iam-authenticator && \
    curl -sL -o aws-iam-authenticator.sha256 https://amazon-eks.s3-us-west-2.amazonaws.com/1.14.6/2019-08-22/bin/linux/amd64/aws-iam-authenticator.sha256 && \
    openssl sha1 -sha256 /usr/local/bin/aws-iam-authenticator && \
    rm ./aws-iam-authenticator.sha256
RUN curl -sL https://github.com/github/hub/releases/download/v2.11.2/hub-linux-amd64-2.11.2.tgz | tar xz -C /tmp/ && \
    mv /tmp/hub-linux-amd64-2.11.2/bin/hub . && \
    chgrp root hub && \
    chown root hub && \
    mv hub /usr/local/bin
RUN curl -sL -o /usr/local/bin/fluxctl https://github.com/fluxcd/flux/releases/download/1.14.2/fluxctl_linux_amd64
RUN curl -sL -o /usr/local/bin/cfssl https://pkg.cfssl.org/R1.2/cfssl_linux-amd64 && \
    curl -sL -o /usr/local/bin/cfssljson https://pkg.cfssl.org/R1.2/cfssljson_linux-amd64 && \
    curl -sL -o /usr/local/bin/cfssl-certinfo https://pkg.cfssl.org/R1.2/cfssl-certinfo_linux-amd64
RUN mv ~/.local/bin/* /usr/local/bin
RUN curl -sL https://github.com/derailed/k9s/releases/download/0.8.4/k9s_0.8.4_Linux_x86_64.tar.gz | tar xz -C /tmp && \
    mv /tmp/k9s /usr/local/bin
RUN curl -sL -o /usr/local/bin/linkerd https://github.com/linkerd/linkerd2/releases/download/stable-2.5.0/linkerd2-cli-stable-2.5.0-linux 
RUN curl -sL -o /usr/local/bin/glooctl https://github.com/solo-io/gloo/releases/download/v0.19.1/glooctl-linux-amd64
COPY tpctl.sh /root/tpctl
COPY separate_files /usr/local/bin/separate_files
COPY external_secret /usr/local/bin/external_secret
RUN ln -s /usr/bin/python3 /usr/local/bin/python3 && chmod +x /usr/local/bin/*
CMD [ "/root/tpctl"  ]
