#!/bin/bash

set -e -u -o pipefail
ROOTDIR=$(cd "$(dirname "$0")" && pwd)

mkdir -p ${ROOTDIR}/_cfg

if [ ! -f .env ]; then
  echo "Please ensure a .env file is present"
  exit 1
fi

docker run --env-file .env -it -v ${ROOTDIR}/_cfg:/workspace/_cfg hlfsupport-in-a-box console
docker run --env-file .env -it -v ${ROOTDIR}/_cfg:/workspace/_cfg hlfsupport-in-a-box network

echo 
echo -----------------------------------------------------------------------------------------------------
echo
echo "Console is available at this URL = " $(cat _cfg/auth-vars.yml | grep api_endpoint | cut -c 15-)
echo
echo "Username = nobody@ibm.com"
echo "Password = new42day"