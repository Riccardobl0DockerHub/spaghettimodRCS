This is a build of [Spaghettimod](https://github.com/pisto/spaghettimod) on which the commit [6e90c481b7144ac0e215a2e270ee29ed6733703f](https://github.com/pisto/spaghettimod/commit/6e90c481b7144ac0e215a2e270ee29ed6733703f) is reverted.

There are some additional tweaks to allow easy deployment of servers with custom maps.


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