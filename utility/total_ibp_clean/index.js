// Apache-2

// Import and IBP Node SDK, and also two cli helpers
const ibp = require('ibp-node-sdk');
const { BasicAuthenticator } = require('ibm-cloud-sdk-core');
const chalk = require('chalk');
const env = require('env-var');
const prettyjson = require("prettyjson-256");
const loadEnv = require('env-yml');
const fs = require('fs');
// Credentials that are required
prettyjson.init({ alphabetizeKeys: true });

const yargs = require('yargs/yargs')(process.argv.slice(2))
let args = yargs
	.option('nossl', { alias: 'n', describe: 'disable the ssl check for self-signed certs'})
	.option('cfg', { alias: 'c', describe: 'path to yml to use for auth'})
	.argv;

if (fs.existsSync(args.cfg)) {
	loadEnv({
		path: args.cfg
	});
}
const ibpendpoint = env.get("api_endpoint").required().asString();
const authtype = env.get("api_authtype").required().asString();
const apikey = env.get("api_key").required().asString();
const apisecret = env.get("api_secret").required().asString();


// the API key, and endpoint need to used here. Get these from a IBP Service Credential
// Create an authenticator
let authenticator;
if (authtype === 'ibmcloud') {
    authenticator = new ibp.IamAuthenticator({
        apikey: apikey,
        url: process.env.API_TOKEN_ENDPOINT
    });
} else {
    authenticator = new BasicAuthenticator({
        username: apikey,
        password: apisecret,
    });
}
//

// Create client from the "BlockchainV3" class
const client = ibp.BlockchainV3.newInstance({
	authenticator,
	url: ibpendpoint,
	disableSslVerification: args.nossl
});

// main method
const main = async () => {

	console.log(chalk.blue("Deleting all the components"));
	let response = await client.deleteAllComponents();
	if (response.status === 200) {
		if (response.result) {
			console.log(prettyjson.render(response.result));
		} else {
			console.log(prettyjson.render(response));
		}
	} else {
		console.log(response);
	}

}

main().then().catch((e) => { console.error(e) })
