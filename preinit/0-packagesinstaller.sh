#!/bin/bash

#package_install Filename+ext path
# eg. package_install a.zip /tmp/a.zip
function package_install {   
    if [[ $1 == *.ogz ]]; #map.ogz
    then
        cp -Rvf "$2" "$PACKAGES/base/$1"
    elif [[ $1 == *.zip ]];
    then
        tmp_f="/tmp/$1.unzip"
        rm -Rf "$tmp_f"		
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
            elif [ -f "$sd/"*.ogz ]; # map.zip/*/map.ogz
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

        rm -Rf "$tmp_f"
    else
        echo "Unknown file extension $1"
    fi
}