
#!/bin/bash
#Usage: Leave MAPS blank
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