#!/bin/bash
# Usage: -eQUADROPOLIS_DL="map1.zip,map2.zip,map3.zip"



if [ "$QUADROPOLIS_DL" != "" ];
then
    IFS=',' 
    for f in `echo "$QUADROPOLIS_DL"`
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
            package_install $f "/tmp/$f"
            rm "/tmp/$f"
            echo "1" > "$PACKAGES/$f.st"
            echo  "write $PACKAGES/$f.st "

        else
            echo "$f already downloaded.  $PACKAGES/$f.st  exists"
        fi
    done
fi
