# HLF-Support-In-A-Box

A single docker image with the Ansible and configuration scripts required to setup the HLFSupport images in an Open Shift Cluster
along with a test Fabric network for 2 organizations.

Everything is contained within a single docker image; this needs a configuration file to point to the cluster, and give credentials.
A local directory can also be mapped that will contain connection information for applications etc. 

## Requirements

- a provisioned openshift cluster
- entitlement credentials for the HLFSupport images
- Docker or podman installed locally
  
- Also create a new empty directory to work in. 
## Configuration

A `.env` file needs to be created that contains the details of the provisioned OpenShift Cluster, along with 
credentials to the docker registry with the images.

A sample `.env` would be

```
OCP_TOKEN_SERVER=https://xxxxxxx:99999
OCP_TOKEN=sha256~<token>7rsaZNbfsJH5wkGQw-xuBUjmlklWTF1yovp3kOBrRdw
CONSOLE_DOMAIN=<domain console will be at - the ingress domain>

DOCKER_PW=<password>
DOCKER_USERNAME=<username>
DOCKER_REPOSITORY=<repository>

```

Create the .env file in the new empty directory

```bash
mkdir hlf && cd hlf
touch .env
# and edit
```

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