# Marvin Container

This is an IBP Development and Build focused container. Intended for use with the Tekton Pipeline for the Marvin test system. It's second use case is for interactive testing similar to Marvin for example with setting up fyre hosted ocp clusters.

It is an extension of the open source hyperledgerary/warp-image 

**warp** /wɔːp/ _noun_ 
(in weaving) the threads on a loom over and under which other threads (the weft) are passed to make cloth.

## Notes on the building and using of the container

The build of the container is straight-forward

```
docker build  -t marvin-container .
```

This is pushed to a private registry in IBM Cloud under the 'Blockchain Brokers' Account: `uk.icr.io/marvin`
This is the account that Marvin itself is run under. Therefore when new images are pushed, these should be done in the
context of this registry.  Tag the image correctly before pushing it to the registry.

Please ensure that you're logged in via the IBMCloud CLI to ensure you have the correct access; follow the guide [here](https://cloud.ibm.com/docs/Registry?topic=Registry-getting-started)

```
docker tag marvin-container:latest uk.icr.io/marvin/marvin-container:3
docker push uk.icr.io/marvin/marvin-container:3
```

To run the container manually to work with either Marvin or other tests remember to pass a `.env` file with properties. This is using the name from a local build. If you've not built this locally, replace with the full registry name as above. 

```
 docker run -it -v ${PWD}:/artifacts --env-file .env --name marvin-container -t marvin-container:latest
```

(aside to login in using the IBM Cloud, the following should be sufficient  `ibmcloud login --sso` choose the Blockchain Brokers account, and then target the 'development' resource group. `ibmcloud target -g Development`)

## Accessing the docker image from a Tekton Pipeline
To access the docker registry from the Tekton Pipelines, a specified secret needs to be provided. This requires an API_KEY from IBM Cloud. 
This then needs to be converted into K8S secret JSON file

```
kubectl create secret docker-registry icr-secret-util --dry-run=true --docker-server="uk.icr.io" --docker-password=${API_KEY} --docker-username=iamapikey --docker-email=a@b.com --output='json'
```

And then get the contents of the `.dockerconfigjson` option - and put this into a secret to to be used in the pipeline.
