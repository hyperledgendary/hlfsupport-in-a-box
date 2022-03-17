# HLF-Support-In-A-Box

A single docker image with the Ansible and configuration scripts required to setup the HLFSupport images in an Open Shift or K8S Cluster
along with a test Fabric Network for 2 organizations.

Everything is contained within a single docker image; this needs a configuration file to point to the cluster, and give the entitlement
key to the IBM Container Library. 

A local directory is also mapped that will contain connection information for applications etc.

---
*For IBM Software Library Images, your entitlement keys can be obtained from [this site](https://myibm.ibm.com/products-services/containerlibrary)*

---

**Uber-quick-start**

- Get a fresh provisioned Linux machine. As this is going to run a cluster locally it needs to have about 8CPUs, 16Gb memory.  
- This will install and setup the Docker, Kind, and basic config for you
```bash
curl -sSL https://raw.githubusercontent.com/hyperledgendary/hlfsupport-in-a-box/main/prereqs.sh -o prereqs.sh && chmod +x prereqs.sh
./prereqs.sh
```

- Add you email and entitlement key to the `cfg.env` file

- Install the HLF support into the local Kind cluster
```bash
curl -sSL https://raw.githubusercontent.com/hyperledgendary/hlfsupport-in-a-box/main/unbox.sh -o unbox.sh && chmod +x unbox.sh
./unbox.sh
```

## Using IBM Cloud Transient Virtual Servers

The IBM Cloud Classic Infrastructure has a class of virtual services defined as "Transient". These are cheap, and fine for exploration usage.

When creating these, it's suggested to use the 8 vCPUs / 16 GB memory. It's worth getting the 100Gb storage just in case.  

Select the Ubuntu 20.04 LTS miniaml as the operating system.



## Detailed Requirements

If you want to use an existing system these are the tools that you will need

- Either provisioned OpenShift cluster or a locally running k8s cluster
- Entitlement credentials for the HLFSupport images
- Docker installed locally
- Suggested that you have some tooling-of-choice to work with your k8s cluster. 
  
- Recommended that you create a directory to work in

- If you want to provision a Linux VM then 8 vCPU, 16Gb Memory are worth getting. 

## Configuration for a Cloud-hosted Cluster

A `cfg.env` file needs to be created that contains the details of the provisioned OpenShift Cluster, along with 
credentials to the docker registry with the images.

This is the example `cfg.env`

```bash
# iks & ocp are all accepted values
#
# iks will assumet the current kubectl context is the one to use
# ocp will use the `oc` cli to login to the cluster
CLUSTER_TYPE=iks

# For OCP token authentication use these settings
OCP_TOKEN_SERVER=api.gabbros.cp.fyre.ibm.com:6443
OCP_TOKEN=sha256~XX

# username/password authentication is possible, comment out the OCP_TOKEN and use these settings
# OCP_URL=uuuu
# OCP_PASSWORD=pppp
# OCP_USERNAME=xxxx

# The domain where the console is to be hosted
CONSOLE_DOMAIN=apps.gabbros.cp.fyre.ibm.com

# Depending on the cluster you might need to alter the storage class being used
# CONSOLE_STORAGE_CLASS=standard

# Credentials to access the IBM Container Library
DOCKER_EMAIL=fred@uk.ibm.com
DOCKER_PW=xxxxxxxxx

```

Create the cfg.env file in the new empty directory

```bash
mkdir hlf && cd hlf
touch cfg.env
# and edit
```

## Configuration for a locally-hosted cluster

This can be run entirely locally on one machine, this is very good for demos and exploration. 
The suggestion is to setup a KIND based k8s cluster. The simplest way to get a good KIND configuration is to use the `test-network-k8s` from the `hyperledger/fabric-samples` github repository

```bash
git clone https://github.com/hyperledger/fabric-samples.git
cd fabric-samples/test-network-k8s
./network kind
```

This setups your local kubcetl context; this means that the `cfg.env` file you need to created is similar to this.
Note that the `console-domain` has an IP address that will needs to resolve to the host that you are running KIND on. A quick way to get this is to issues `hostname -I` and use the first IP address returned.

```bash
CLUSTER_TYPE=iks
CONSOLE_DOMAIN=172-22-140-212.nip.io
CONSOLE_STORAGE_CLASS=standard

DOCKER_EMAIL=fred@example.com
DOCKER_PW=<image entitlement key>
```

## Storage Classes
Depending on creation, the storage classes may might need to be configured. The `scripts/setup_storage_classes.sh` can be used in this.

## Running

- Get the 'unbox.sh' script... this has the docker run commands in it to save typing

```
curl -sSL https://raw.githubusercontent.com/hyperledgendary/hlfsupport-in-a-box/main/unbox.sh -o unbox.sh && chmod +x unbox.sh
```

- Run the unbox script

```bash
./unbox.sh
```

The process will take about 10 minutes depending on network speeds etc.

When complete, a message will be printed with where the Console is running, and the local `_cfg` directory will contain configuration files to help connect applications.