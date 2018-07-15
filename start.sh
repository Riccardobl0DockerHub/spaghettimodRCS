#!/bin/bash

set -e

if [ "$PACKAGES" = "" ];
then
    export PACKAGES=/opt/packages
fi

if [ "$SCRIPT" = "" ];
then
    export SCRIPT=/opt/script
fi

mkdir -p $PACKAGES/base


if [ -f "$SCRIPT/init.sh" ];
then
    source "$SCRIPT/init.sh"
    init
fi



set +e 
cp -Rf /opt/preinit/* /opt/spaghettimod/preinit/
set -e
for sscript in /opt/spaghettimod/preinit/*.sh
do
    source "$sscript"
done
set +e 
cp -Rf /opt/script/* /opt/spaghettimod/script/
cp -Rf /opt/packages/* /opt/spaghettimod/packages/
set -e

cd /opt/spaghettimod
echo "cs.serverdesc = \"$SERVER_DESC\"">script/load.d/200-servername.lua
echo "Run master server for $SERVER_IP"
if [ "$NO_MASTER" = "" ];
then
    cd ./script/std/
    cp -f /opt/rcs_pseudomaster .
    chmod +x rcs_pseudomaster
    ./rcs_pseudomaster $SERVER_IP &
    cd ../../
fi
./sauer_server