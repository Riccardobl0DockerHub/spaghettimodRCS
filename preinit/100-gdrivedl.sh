#!/bin/bash
#Usage -eDRIVE_DL="ID:file.zip,ID:file.zip"
#https://gist.github.com/iamtekeste/3cdfd0366ebfd2c0d805
function gdrive_download {
  CONFIRM=$(wget --quiet --save-cookies /tmp/cookies.txt --keep-session-cookies --no-check-certificate "https://docs.google.com/uc?export=download&id=$1" -O- | sed -rn 's/.*confirm=([0-9A-Za-z_]+).*/\1\n/p')
  wget --load-cookies /tmp/cookies.txt "https://docs.google.com/uc?export=download&confirm=$CONFIRM&id=$1" -O $2
  rm -rf /tmp/cookies.txt
}

if [ "$GDRIVE_DL" != "" ];
then
    IFS=',' 
    for f in `echo "$GDRIVE_DL"`
    do 
        IFS=':' read -a parts <<< "$f"
        IFS=',' 
        f="${parts[1]}"
        id="${parts[0]}"
        if [ ! -f "$PACKAGES/$f.st" ];
        then
            echo  "$PACKAGES/$f.st doesnt exist, download..."
            if [ "$f" == "" ];
            then
                continue
            fi
           
            echo "Download GDRIVE id:$id in /tmp/$f"
            gdrive_download $id "/tmp/$f"
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


