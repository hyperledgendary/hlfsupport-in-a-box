#!/usr/bin/env node
// Apache-2

// Import and IBP Node SDK, and also two cli helpers
const ibp = require('ibp-node-sdk');
const { table } = require('table');
const chalk = require('chalk');
const semver = require('semver');
const { BasicAuthenticator } = require('ibm-cloud-sdk-core');
const loadEnv = require('env-yml');
const prettyjson = require("prettyjson-256");
prettyjson.init({ alphabetizeKeys: true });

const yargs = require('yargs/yargs')(process.argv.slice(2))
let args = yargs
    .option('yml', { alias: 'y', describe: 'output the latest in yaml format' })
    .option('nossl', { alias: 'n', describe: 'disable the ssl check for self-signed certs' })
    .option('cfg', { alias: 'c', describe: 'path to yml to use for auth', required:true })
    .option('raw', {  describe: 'output just the raw data'})
    .option('cooked', {  describe: 'output just the raw data, but in a easier to consume form'})
    .argv;

loadEnv({
        path: args.cfg});
    
const env = require('env-var');
// Credentials that are required
const ibpendpoint = env.get("api_endpoint").required().asString();
const authtype = env.get("api_authtype").required().asString();
const apikey = env.get("api_key").required().asString();
const apisecret = env.get("api_secret").required().asString();
const apitokenendpoint = env.get("api_token_endpoint").asString();

// the API key, and endpoint need to used here. Get these from a IBP Service Credential
// Create an authenticator
let authenticator;
if (authtype === 'ibmcloud') {
    authenticator = new ibp.IamAuthenticator({
        apikey: apikey,
        url: apitokenendpoint
    });
} else {
    authenticator = new BasicAuthenticator({
        username: apikey,
        password: apisecret,
    });
}
// Create client from the "BlockchainV3" class
const client = ibp.BlockchainV3.newInstance({
    authenticator,
    url: ibpendpoint,
    disableSslVerification: args.nossl
});

// utility to format the json object
const format = (results, title, data) => {
    for (const key in results) {
        const version = results[key];
        if (version.default) {
            data.push([chalk.bold(title), chalk.bold(version.version), chalk.bold.blueBright('*')])
        } else {
            data.push([title, version.version, ''])
        }
    }
}

const humanOutput = (results) => {
    let data = [[chalk.bold('Component'), chalk.bold('Version'), chalk.bold('Default')]];
    format(results.ca, 'ca', data);
    format(results.peer, 'peer', data);
    format(results.orderer, 'orderer', data);

    tableconfig = {
        columns: {
            0: {
                alignment: 'left',
                width: 10,

            },
            1: {
                alignment: 'center',
                width: 10
            },
            2: {
                alignment: 'right',
                width: 10
            }
        }
    };

    console.log(table(data));
}

const yml = (results) => {

    const reduceFn = (latestVersion, candidateVersion) => {
        let va = candidateVersion.version;
        if (semver.gt(va, latestVersion)) {
            return va;
        } else {
            return latestVersion;
        }
    }

    let calatest = Object.values(results.ca).reduce(reduceFn, '0.0.0');
    console.log(`ca_version: ${calatest}`);

    let peerlatest = Object.values(results.peer).reduce(reduceFn, '0.0.0');
    console.log(`peer_version: ${peerlatest}`);

    let ordererlatest = Object.values(results.orderer).reduce(reduceFn, '0.0.0');
    console.log(`ordering_service_version: ${ordererlatest}`);

}

// main method
const main = async () => {

    response = await client.getFabVersions();
	if (args.raw){
        console.log(JSON.stringify(response.result));
    } else if (args.cooked){
        console.log(prettyjson.render(response.result));  
    } else {
        let results = response.result.versions;
        if (args.yml) {
            yml(results);
        } else {
            humanOutput(results);
        }    
    }

}

main().then().catch((e) => { console.error(e) })
