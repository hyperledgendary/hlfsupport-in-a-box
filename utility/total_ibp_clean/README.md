# IBP Console Versions

This is a simple usage of the IBP Console API to determine the versions of peers, orderers, ca, etc that can be used in ansible scripts.

## Environment variables

You will need the IBP Console Service Credential and API Endpoint. You might also need a the token endpoint if not using the 'prod' instance.
Easiest way is to have a `.env` file like this


```
IBP_KEY=<apikey>
IBP_ENDPOINT=<api_endpoint>
API_TOKEN_ENDPOINT=https://iam.test.cloud.ibm.com/identity/token
```

You can set these all in one go like this
```
export $(grep -v '^#' .env | xargs)
```

## Running the tool

Requires node v12.  Run `npm install` followed by `node index.js`

Assuming the environment variables are set correctly:

```
 node index.js
╔═══════════╤═════════╤═════════╗
║ Component │ Version │ Default ║
╟───────────┼─────────┼─────────╢
║ ca        │ 1.4.9-5 │ *       ║
╟───────────┼─────────┼─────────╢
║ peer      │ 1.4.9-5 │ *       ║
╟───────────┼─────────┼─────────╢
║ peer      │ 2.2.1-5 │         ║
╟───────────┼─────────┼─────────╢
║ orderer   │ 1.4.9-5 │ *       ║
╟───────────┼─────────┼─────────╢
║ orderer   │ 2.2.1-5 │         ║
╚═══════════╧═════════╧═════════╝
```

This is from a staging instance. 