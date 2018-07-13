#!/bin/bash

set -e

export PACKAGES=/opt/packages
mkdir -p $PACKAGES/base

function install {
   
    if [[ $1 == *.ogz ]]; #map.ogz
    then
        cp -Rvf "$2" "$PACKAGES/base/$1"
    elif [[ $1 == *.zip ]];
    then
        tmp_f="/tmp/$1.unzip"
        rm -Rvf "$tmp_f"		
        mkdir -p "$tmp_f"
        unzip $2 -d $tmp_f
        dd=0
        cdir="$PWD"
        cd $tmp_f
        for sd in *
        do
           if [ "$sd" == "packages" ]; # map.zip/packages/base/map.ogz
           then
                cp -Rvf "$sd"/* "$PACKAGES/"
                dd=1
                break
            elif [ -d "$sd/packages" ]; #map.zip/map/packages/base/map.ogz
            then
                cp -Rvf "$sd/packages"/* "$PACKAGES/"
                dd=1
            elif [ -d "$sd/map" ]; #map.zip/media/map/map.ogz
            then
                cp -Rvf "$sd/map"/* "$PACKAGES/"
                dd=1
            elif [[ $sd  == *.ogz ]]; #map.zip/map.ogz
            then
                cp -Rvf "$sd" "$PACKAGES/base/"
                dd=1
            elif [[ $sd  == *.cfg ]]; #map.zip/map.ogz
            then
                cp -Rvf "$sd" "$PACKAGES/base/"
            elif [ "$sd" == "base" ]; # map.zip/base/map.ogz
            then
                cp -Rvf "$sd"/* "$PACKAGES/base/"
                dd=1               
            fi
        done
        if [ "$dd" == "0" ]; 
        then
            echo "Unrecognized file layout"
            ls -lh "$tmp_f"
        fi
        cd $cdir

        rm -Rvf "$tmp_f"
    else
        echo "Unknown file extension $1"
    fi
}

if [ "$MAP_DL" != "" ];
then
    IFS=',' 
    for f in `echo "$MAP_DL"`
    do 
        if [ ! -f "$PACKAGES/$f.st" ];
        then
            echo  "$PACKAGES/$f.st doesnt exist, download..."
            if [ "$f" == "" ];
            then
                continue
            fi
            echo "Download $f..."
            wget "http://quadropolis.us/files/$f" -O "/tmp/$f"
            echo "Install $f"
            install $f "/tmp/$f"
            rm "/tmp/$f"
            echo "1" > "$PACKAGES/$f.st"
            echo  "write $PACKAGES/$f.st "

        else
            echo "$f already downloaded.  $PACKAGES/$f.st  exists"
        fi
    done
fi

if [ "$MAPS" == "" ];
then
    echo "List maps"
    cdir="$PWD"
    cd "$PACKAGES/base"
    export MAPS=""
    for f in *.ogz;
    do
        map="${f%.*}"
        if [ "$MAPS" != "" ]
        then
        export MAPS="$MAPS $map"
        else
            export MAPS="$map"
        fi
    done
    echo $MAPS
fi
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