#!/usr/bin/env node

const semver = require('semver');
var isTTY = process.stdin.isTTY;
var stdin = process.stdin;
const yargs = require('yargs/yargs')(process.argv.slice(2))

let args = yargs
    .option('arch', { alias: 'a', describe: 'architecture' })
    .option('vermatch', { alias: 'm', describe: 'Semver Version match  eg ^2.5' })
    .argv;

const main = async () =>{
    let tags = JSON.parse(await handlePipedContent())['tags'];
    let archRegex = new RegExp(`${args.arch}$`);

    let o = tags.filter((v)=>{
        return v.match(archRegex)
    }).filter((v)=>{
        return semver.satisfies(semver.coerce(v),args.vermatch);
    }).sort((a,b)=>{
      let av =  semver.coerce(a);
      let bv = semver.coerce(b);
      if (semver.lt(av,bv)){
          return 1;
      } else if (semver.gt(av,bv)) {
          return -1;
      } else {
          return 0;
      };
    });

    // list is now ordered into semver order

    let s= o[0].substring(0,o[0].indexOf('-'));
    let verRegex = new RegExp(`^${s}`);
    let p = o.filter((v)=>{
        return v.match(verRegex)
    }).sort((a,b)=>{
        let av = a.split('-')[1];
        let bv = b.split('-')[1];

        return bv-av;
    });

    console.log(p[0]);
}

const handlePipedContent = async () => {
    var data = '';
    
    return new Promise((resolve,reject)=>{
        stdin.on('readable', function() {
            var chuck = stdin.read();
            if(chuck !== null){
                data += chuck;
            }
        });
        stdin.on('end', function() {
            resolve(data);
        });
    })
}

main().catch(e=>console.log(e));