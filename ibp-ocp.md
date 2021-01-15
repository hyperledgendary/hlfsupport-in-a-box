
# Running pre-release IBP 

AIM: To run a pre-release IBP in an OpenShift Cluster

## Pre-reqs

- OC binary
- docker-ls
- jq
- ansible & ibm collection

(or use the warp-image docker image)

## OpenShift 

**Create an OpenShift Cluster**

- Log onto 'fyre.ibm.com/quick'
  - first time need to request permission to use the QuickBurn service
- Select 'X' and 'OpenShift' and choose a version. 
- Select the 'medium' size
- No additional options needed, unless you want a specific cluster name.
- Accept the default time.
- click the 'I Understand' box and click 'create embers'
    - the notification it has been accepted is sublte, so be careful not to create two clusters.
- An email will come when this has been created. 

> Your OpenShift cluster 'nx01' has finished building.
> You may now access your OpenShift portal here:
> 
>https://console-openshift-console.apps.nx01.cp.fyre.ibm.com
>
>Credentials for OpenShift Portal:
>
>Username: kubeadmin
>Password: MK2Xw-F52Be-hi4Yw-vTuKG
>
> Infrastructure Node:
>
> api.nx01.cp.fyre.ibm.com

```
export OCP_ACCESS_URL=$(cat .env | jq -r .access_url | sed -e s/console-openshift-console.apps/api/  -e s/$/:6443/)
export OCP_PASSWORD=$(cat .env | jq -r .kubeadmin_password)
oc login ${OCP_ACCESS_URL} --username=kubeadmin --password=${OCP_PASSWORD} --insecure-skip-tls-verify=true
````

## Local Environment

You need a local environment setup with all the prereqs. If you're the preqeqs locally, great. Or use this docker image

```
docker run -it -v ${PWD}:/home/fabdev/local -e IBP_KEY=nobody@ibm.com calanais/warp
```

Now login to the OpenShift portal with the address in the email with the username and password. Note that this site uses self-signed certifcates that browsers will complain about; accept them as acceptable.

From the menu top right, seleck the `cli login` option and click `display token`.  Copy the `oc login....` command and run this in shell created in the previous step.

Again a warning will be given about the self-signed cert. Accept this.


**Storage Classes**
The fyre cluster doesn't have any Storage Classes setup, so run the `setup_storageclasses.sh` script (already in the container)

**Ansible playbooks**
To install IBP you need some Ansible Playbooks. There as a script to create these: `create_playbooks.sh`. The one thing to change in this script is the `CONSOLE_DOMAIN`. Change it to the infrastructure node from the email.

eg.. in the file there is 
```
CONSOLE_DOMAIN=apps.nx01.cp.fyre.ibm.com
```

If your new cluster is `console-openshift-console.apps.letup.cp.fyre.ibm.com`

Make a copy and change the fie to 

```
CONSOLE_DOMAIN=apps.letup.cp.fyre.ibm.com
```


Run the `create_playbooks.sh` (or your modified version) script - this should create two files. `latest-crds.yml` and `latest.yml`


```
ansible-playbook latest-crds.yml
ansible-playbook latest.yml
```


Finally there will a message 

```
TASK [ibm.blockchain_platform.console : Print console URL] *********************************************************************************************************************
ok: [localhost] => {
    "msg": "IBM Blockchain Platform console available at https://ibp-zeta-ibp-console-console.apps.letup.cp.fyre.ibm.com"
}
```

# IBP Setup

Default email and password are `nobody@ibm.com` &  `new42day`.
You'll need to change these first time they are used.
