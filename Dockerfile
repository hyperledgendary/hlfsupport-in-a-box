#
# SPDX-License-Identifier: Apache-2.0
#
FROM ibmcom/pipeline-base-image:2.11

RUN apt-get update \
    && apt-get -y upgrade \
    && apt-get -y install build-essential gcc gzip \
                  python3.8 python3-distutils libpython3.8-dev software-properties-common \       
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

# Golang
RUN mkdir -p /opt/go \
    && curl -sSL https://dl.google.com/go/go1.14.3.linux-amd64.tar.gz | tar xzf - -C /opt/go --strip-components=1 
ENV GOROOT=/opt/go
ENV GOCACHE=/tmp/gocache
ENV GOENV=/tmp/goenv
ENV GOPATH=/tmp/go
ENV PATH=/opt/go/bin:${PATH}

# Python & Ansible
RUN curl https://bootstrap.pypa.io/get-pip.py -o get-pip.py \
    && python3.8 get-pip.py  \
    && pip3.8 install  "ansible>=2.9,<2.10" fabric-sdk-py python-pkcs11 openshift semantic_version\
    && ansible --version \
    && ansible-galaxy collection install ibm.blockchain_platform -f

## Node
ENV NODE_VERSION 14.15.4
RUN  export NVM_DIR="$HOME/.nvm" \
     && . "$NVM_DIR/nvm.sh" \
     && nvm install $NODE_VERSION \
     && nvm alias default $NODE_VERSION \
     && nvm use default \ 
     && npm install --unsafe-perm -g @hyperledgendary/weftility@0.0.7

RUN mkdir -p /opt/fabric \
    && curl -sSL https://github.com/hyperledger/fabric/releases/download/v2.2.1/hyperledger-fabric-linux-amd64-2.2.1.tar.gz | tar xzf - -C /opt/fabric  \
    && curl -sSL https://github.com/hyperledger/fabric-ca/releases/download/v1.4.9/hyperledger-fabric-ca-linux-amd64-1.4.9.tar.gz | tar xzf - -C /opt/fabric
ENV FABRIC_CFG_PATH=/opt/fabric/config
ENV PATH=/opt/fabric/bin:${PATH}

# Add editor
RUN cd /usr/local/bin; curl https://getmic.ro | bash \
    && curl -sL https://github.com/jt-nti/cds-cli/releases/download/0.3.0/cds-0.3.0-linux > /opt/fabric/bin/cds && chmod +x /opt/fabric/bin/cds

COPY create_playbooks.sh /opt/fabric/bin/ 
COPY setup_storageclasses.sh /opt/fabric/bin/

WORKDIR /artifacts
