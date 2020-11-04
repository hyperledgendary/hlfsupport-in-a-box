#
# SPDX-License-Identifier: Apache-2.0
#
FROM ubuntu:latest
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update \
    && apt-get -y upgrade \
    && apt-get -y install curl build-essential gcc gzip sudo git \
                  python3.8 python3-distutils libpython3.8-dev unzip sudo zip \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

RUN curl https://mirror.openshift.com/pub/openshift-v4/clients/oc/4.6.0-202005061824.git.1.7376912.el7/linux/oc.tar.gz --output oc.tar.gz \
   && tar xvzf oc.tar.gz \
   && chmod u+x ./oc \
   && mv ./oc /usr/local/bin/oc

RUN curl -L https://github.com/mayflower/docker-ls/releases/download/v0.3.2/docker-ls-linux-amd64.zip --output docker-ls.zip \
   && unzip docker-ls.zip \
   && chmod u+x docker-ls \
   && mv docker-ls /usr/local/bin/ \
   && chmod u+x docker-rm \
   && mv docker-rm /usr/local/bin/

RUN . /etc/os-release \
     && echo "deb https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable/xUbuntu_${VERSION_ID}/ /" |  tee /etc/apt/sources.list.d/devel:kubic:libcontainers:stable.list \
     && curl -L https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable/xUbuntu_${VERSION_ID}/Release.key |  apt-key add -  \
     && apt-get update  \
     && apt-get -y upgrade  \
     && apt-get -y install podman

ENV DOCKERVERSION=19.03.8
RUN curl -fsSLO https://download.docker.com/linux/static/stable/x86_64/docker-${DOCKERVERSION}.tgz \
  && tar xzvf docker-${DOCKERVERSION}.tgz --strip 1 \
                 -C /usr/local/bin docker/docker \
  && rm docker-${DOCKERVERSION}.tgz

# Replace shell with bash so we can source files
RUN rm /bin/sh && ln -s /bin/bash /bin/sh

RUN useradd -ms /bin/bash fabdev 
RUN usermod -aG sudo fabdev
RUN groupadd docker
RUN usermod -aG docker fabdev

# Golang
RUN mkdir -p /opt/go \
    && curl -sSL https://dl.google.com/go/go1.14.3.linux-amd64.tar.gz | tar xzf - -C /opt/go --strip-components=1 
ENV GOROOT=/opt/go
ENV GOCACHE=/tmp/gocache
ENV GOENV=/tmp/goenv
ENV GOPATH=/tmp/go

USER fabdev
WORKDIR /home/fabdev
ENV PATH=/home/fabdev/.local/bin:$PATH

# Python & Ansible
RUN curl https://bootstrap.pypa.io/get-pip.py -o get-pip.py \
    && python3.8 get-pip.py 
RUN pip3.8 install --user "ansible>=2.9,<2.10" fabric-sdk-py python-pkcs11 openshift

RUN ansible --version \
    && ansible-galaxy collection install ibm.blockchain_platform -f

## Node
ENV NODE_VERSION 14.11.0
RUN curl https://raw.githubusercontent.com/creationix/nvm/v0.36.0/install.sh | bash \
    && export NVM_DIR="$HOME/.nvm" \
    && source "$NVM_DIR/nvm.sh" \
    && nvm install $NODE_VERSION \
    && nvm alias default $NODE_VERSION \
    && nvm use default \ 
    && npm install -g @hyperledgendary/weftility@0.0.7

## SDKMan
RUN curl -s "https://get.sdkman.io" | bash
RUN source "$HOME/.sdkman/bin/sdkman-init.sh" \
    && sdk version \
    && sdk install java 11.0.9.hs-adpt



# Peer commands
WORKDIR /home/fabdev/.local
RUN curl -sSL https://bit.ly/2ysbOFE | bash -s -- 2.2.0 1.4.8 -s -d

ENV FABRIC_CFG_PATH=/home/fabdev/.local/config

COPY create_playbooks.sh /home/fabdev/
COPY setup_storageclasses.sh /home/fabdev/

WORKDIR /home/fabdev
