#
# SPDX-License-Identifier: Apache-2.0
#
FROM ibmcom/pipeline-base-image:2.11

# Build tools
RUN apt-get update \
    && apt-get -y upgrade \
    && apt-get -y install build-essential gcc gzip \
                  python3.8 python3-distutils libpython3.8-dev software-properties-common \       
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Kube CLI (and OpenShift wrapper)
RUN curl https://mirror.openshift.com/pub/openshift-v4/clients/oc/4.6.0-202005061824.git.1.7376912.el7/linux/oc.tar.gz --output oc.tar.gz \
   && tar xvzf oc.tar.gz \
   && chmod u+x ./oc \
   && mv ./oc /usr/local/bin/oc

# Docker-ls (for ansible playbook generation)
RUN curl -L https://github.com/mayflower/docker-ls/releases/download/v0.3.2/docker-ls-linux-amd64.zip --output docker-ls.zip \
   && unzip docker-ls.zip \
   && chmod u+x docker-ls \
   && mv docker-ls /usr/local/bin/ \
   && chmod u+x docker-rm \
   && mv docker-rm /usr/local/bin/

# Terraform v12.30 (https://releases.hashicorp.com/terraform/0.12.30/)
RUN curl -L https://releases.hashicorp.com/terraform/0.12.30/terraform_0.12.30_linux_amd64.zip --output terraform.zip \
   && unzip terraform.zip \
   && chmod u+x terraform \
   && mv terraform /usr/local/bin/ \
   && terraform --version

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

# Node
ENV NODE_VERSION 14.15.4
RUN export NVM_DIR="$HOME/.nvm" \
    && . "$NVM_DIR/nvm.sh" \
    && nvm install $NODE_VERSION \
    && nvm alias default $NODE_VERSION \
    && nvm use default \ 
    && npm install --unsafe-perm -g @hyperledgendary/weftility@0.0.7

ENV CHROME_SOURCE_URL=https://dl.google.com/dl/linux/direct/google-chrome-stable_current_amd64.deb
RUN INSTALL_PATH=/tmp/$(basename $CHROME_SOURCE_URL) \
    && apt-get update \
    && apt-get install -y gconf-service libasound2 libatk1.0-0 libcairo2 libcups2 libfontconfig1 libgdk-pixbuf2.0-0 libgtk-3-0 libnspr4 libpango-1.0-0 libxss1 fonts-liberation libappindicator1 libnss3 lsb-release xdg-utils \
    && wget --no-verbose -O $INSTALL_PATH  $CHROME_SOURCE_URL \
    && apt -y install $INSTALL_PATH \
    && apt -y install xvfb

# Fabric tooling
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

# IBM Terraform provider binary v1.2 (https://github.com/IBM-Cloud/terraform-provider-ibm/releases/download/v1.20.0/terraform-provider-ibm_1.20.0_linux_amd64.zip)
RUN mkdir /root/.terraform.d/plugins \
   && curl -L https://github.com/IBM-Cloud/terraform-provider-ibm/releases/download/v1.20.1/linux_amd64.zip --output /root/.terraform.d/plugins/terraform_p.zip \
   && unzip /root/.terraform.d/plugins/terraform_p.zip -d /root/.terraform.d/plugins

# IBM Cloud CLI
RUN curl -sL https://raw.githubusercontent.com/IBM-Cloud/ibm-cloud-developer-tools/master/linux-installer/idt-installer | bash

WORKDIR /artifacts

