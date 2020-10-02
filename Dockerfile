#
# SPDX-License-Identifier: Apache-2.0
#
FROM ubuntu:latest
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get upgrade -y
RUN apt-get install curl build-essential gcc zip gzip software-properties-common python3.8 python3-distutils libpython3.8-dev unzip -y

# Replace shell with bash so we can source files
RUN rm /bin/sh && ln -s /bin/bash /bin/sh

RUN useradd -ms /bin/bash fabdev  && usermod -aG sudo fabdev
USER fabdev
WORKDIR /home/fabdev
ENV PATH=/home/fabdev/.local/bin:$PATH

# Python & Ansible
RUN curl https://bootstrap.pypa.io/get-pip.py -o get-pip.py \
    && python3.8 get-pip.py 
RUN pip3.8 install --user "ansible>=2.9,<2.10" fabric-sdk-py python-pkcs11 openshift

RUN ansible --version \
    && ansible-galaxy collection install ibm.blockchain_platform

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
    && sdk install java 11.0.8.hs-adpt

# Peer commands
WORKDIR /home/fabdev/.local
RUN curl -sSL https://bit.ly/2ysbOFE | bash -s -- 2.2.0 1.4.8 -s -d

ENV FABRIC_CFG_PATH=/home/fabdev/.local/config

WORKDIR /home/fabdev
