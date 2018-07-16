This is a build of [Spaghettimod](https://github.com/pisto/spaghettimod) on which the commit [6e90c481b7144ac0e215a2e270ee29ed6733703f](https://github.com/pisto/spaghettimod/commit/6e90c481b7144ac0e215a2e270ee29ed6733703f) is reverted.

There are some additional tweaks to allow easy deployment of servers with custom maps.

[![Docker Hub build](https://dockerbuildbadges.quelltext.eu/status.svg?organization=riccardoblb&repository=spaghettimodrcs&tag=amd64)](https://hub.docker.com/r/riccardoblb/spaghettimodrcs/)

# DOCUMENTATION is WIP

Usage (TODO: need better documentation)
```
mkdir -p /srv/sauerrcp/packages
mkdir -p /srv/sauerrcp/script
mkdir -p /srv/sauerrcp/var
chown 1000:1000 -Rf /srv/sauerrcp

docker run --restart=always  --name="sauerrcs" -d \
-eSERVER_PORT="2785" \
-eMAX_PLAYERS="16" \
-eSERVER_DESC="SERVERNAME" \
-eSERVER_TAG="ctf" \
-eMODE1="efficctf" \
-eMODE2="ctf" \
-eMODE3="instactf" \
-eMODE1_ID="17" \
-eMODE2_ID="11" \
-eMODE3_ID="12" \
-eMAPS="" \
-eAUTH_DOMAIN="authdomain" \
-eADMIN="admin" \
-eADMIN_KEY="XXXXXXXXX" \
-eSERVER_IP="127.0.0.1" \
-eMASTER_IP="127.0.0.1" \
-eMAP_DL="nopstation.ogz,rkc2-fallen.zip,tatooine.zip,bran1.zip,alphacorp_release.zip,dam2.zip,watertemple.zip,steelribs.zip,dust6.zip,surreal.zip,gonads_cesspool_V2-20131215.zip,Albion.zip,rush.zip,kronos.zip,Q3Tourney6.zip,burg.zip,packages_16.zip,mordekaiser.zip" \
-p2784:2784 -p2784:2784/udp -p2785:2785 -p2785:2785/udp -p2786:2786 -p2786:2786/udp -p28787:28787 -p28787:28787/udp \
-v/srv/sauerrcp/packages:/opt/packages \
-v/srv/sauerrcp/script:/opt/script \
-v/srv/sauerrcp/var:/opt/spaghettimod/var \
sauerrcs:amd64
```

## Basic configuration

```bash
-eSERVER_PORT="28785" 
-eMAX_PLAYERS="8" 
-eSERVER_DESC="\f4 MY TEST SERVER" 
-eSERVER_TAG="mytestserver" 
-eMODE="ffa"
```

## Quick auth configuration

```bash
-eAUTH_DOMAIN="XXXXXXXx" 
-eADMIN="XXXXXXXXXX" 
-eADMIN_KEY="XXXXXXXXx" 
```

## RCS master server configuration
```bash
-eMASTER_IP="IP that will be shown to the players when asked to install RCS" 
-eSERVER_IP="IP of the current server that will be whitelisted to run RCS" 
```
When running multiple instances of this container on the same IP, you can share a single master server by disabling it on all but one instance by using  `-eNO_MASTER="1"`

## Map list
The map list can be provided via the env variable `MAP`, if nothing is provided, the startup script will try to list all available maps from `packages/base`. The variable takes a list of values separated by a space (not a comma).
```bash
-eMAPS="ventania angkor hdm3"
```


## Sauer World map pack
The container can be configured to use sauer world map pack by setting the environment variable `USE_SWMAPPACK`:
```bash
-eUSE_SWMAPPACK="1"
```

## Quadropolis Downloader
The env var `QUADROPOLIS_DL` allows to download additional maps from quadropolis provided that they are hosted directly on quadropolis servers (no mediafire/dropbox/google drive/etc supported atm).

The variable takes as value a comma separated list like this:
```bash
-eQUADROPOLIS_DL="ventania.zip,angkor.zip,hdm3.zip"
```
the startup script will append `http://quadropolis.us/files/` to every value and will try to download and install the maps.

## Goodle Drive Downloader
The container can also download maps from google drive with the env variable `GDRIVE_DL`.

The variable takes a comma separated list of ids followed by a colon and the file name.

For example if you want to download these two files

`
MapPack1.zip: https://drive.google.com/open?id=XXXX 
MapPack2.zip: https://drive.google.com/open?id=YYYY
`

The `GDRIVE_DL` variable must be set as 
```bash
-eGDRIVE_DL="XXXX:MapPack1.zip,YYYY:MapPack2.zip"
```
## Advance configurarion

### PreInit scripts
### load.d and other startup scripts
