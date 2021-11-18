#
# SPDX-License-Identifier: Apache-2.0
#
FROM ubuntu:latest

ENV DEBIAN_FRONTEND=noninteractive 

# Build tools
RUN apt-get update \
    && apt-get -y upgrade \
    && apt-get -y --no-install-recommends install curl build-essential gcc gzip \
    python3.8 python3-distutils libpython3.8-dev software-properties-common zip unzip \
    git jq\       
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Kube CLI (and OpenShift wrapper)
RUN curl https://mirror.openshift.com/pub/openshift-v4/clients/oc/4.6.0-202005061824.git.1.7376912.el7/linux/oc.tar.gz --output oc.tar.gz \
    && tar xvzf oc.tar.gz \
    && chmod u+x ./oc \
    && mv ./oc /usr/local/bin/oc

RUN curl -LO https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl \
    && install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl 

# Docker-ls (for ansible playbook generation)
RUN curl -L https://github.com/mayflower/docker-ls/releases/download/v0.3.2/docker-ls-linux-amd64.zip --output docker-ls.zip \
    && unzip docker-ls.zip \
    && chmod u+x docker-ls \
    && mv docker-ls /usr/local/bin/ \
    && chmod u+x docker-rm \
    && mv docker-rm /usr/local/bin/

# Fabric tooling
RUN mkdir -p /opt/fabric \
    && curl -sSL https://github.com/hyperledger/fabric/releases/download/v2.2.1/hyperledger-fabric-linux-amd64-2.2.1.tar.gz | tar xzf - -C /opt/fabric  \
    && curl -sSL https://github.com/hyperledger/fabric-ca/releases/download/v1.4.9/hyperledger-fabric-ca-linux-amd64-1.4.9.tar.gz | tar xzf - -C /opt/fabric
ENV FABRIC_CFG_PATH=/opt/fabric/config
ENV PATH=/opt/fabric/bin:${PATH}

# Add editor
RUN cd /usr/local/bin; curl https://getmic.ro | bash \
    && curl -sL https://github.com/jt-nti/cds-cli/releases/download/0.3.0/cds-0.3.0-linux > /opt/fabric/bin/cds && chmod +x /opt/fabric/bin/cds

# IBM Cloud CLI
#RUN curl -sL https://raw.githubusercontent.com/IBM-Cloud/ibm-cloud-developer-tools/master/linux-installer/idt-installer | bash
RUN curl -fsSL https://clis.cloud.ibm.com/install/linux | sh

# Python & Ansible
RUN curl https://bootstrap.pypa.io/get-pip.py -o get-pip.py \
    && python3.8 get-pip.py  \
    && pip3.8 install  "ansible>=2.9,<2.10" fabric-sdk-py python-pkcs11 openshift semantic_version\
    && ansible --version 

RUN mkdir -p /workspace \
    && git clone -b main https://github.com/IBM-Blockchain/ansible-collection.git /workspace/ansible-collection \
    && ansible-galaxy collection build /workspace/ansible-collection -f \
    && ansible-galaxy collection install /ibm-blockchain_platform-*.tar.gz -f

RUN curl --proto '=https' --tlsv1.2 -sSf https://just.systems/install.sh | bash -s -- --to /usr/local/bin

RUN curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.38.0/install.sh | bash \
    && . /root/.nvm/nvm.sh \
    && nvm install v14.18.1 \
    && nvm alias default 14.18.1 \
    && nvm use default 


WORKDIR /workspace
COPY scripts /workspace/scripts
COPY utility /workspace/utility
COPY playbooks /workspace/playbooks
COPY justfile /workspace/
RUN . /root/.nvm/nvm.sh && npm --prefix /workspace/utility/ibp_hlf_versions install


ENTRYPOINT ["just"]