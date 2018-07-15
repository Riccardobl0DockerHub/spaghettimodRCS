#!/bin/bash
# Usage: -eUSE_SWMAPPACK=1
#http://www.sauerworld.org/sauerworld-mappack/
    if [ "$USE_SWMAPPACK" != "" ];
    then
        if [ ! -f "$PACKAGES/swmaps.st" ];
        then
            echo "Download SW mappack..."
            wget http://www.sauerworld.org/swmaps-12Mar2017.zip -O /tmp/swmaps.zip
            echo "install SW mappack..."
            cd /tmp
            unzip swmaps.zip
            cd swmaps*
            cp -Rf packages/* "$PACKAGES/"
            cd ..
            rm -Rf swmaps*
            echo "1" > "$PACKAGES/swmaps.st"
            echo "Done."
        else
            echo "SW map pack already installed!"
        fi
    fi
