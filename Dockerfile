FROM ubuntu:xenial

RUN apt-get update&& apt-get -y install git net-tools \
&&apt-get -y install luajit libluajit-5.1-dev luarocks socat  zlib1g-dev\
&& luarocks install uuid \
&& luarocks install dkjson \
&& luarocks install mmdblua \
&& luarocks install luaposix 

RUN cd /opt\
&&  git config --global user.email "tmp@email.root"\
    &&git clone https://github.com/pisto/spaghettimod.git\
&&cd spaghettimod\
&&git revert 6e90c481b7144ac0e215a2e270ee29ed6733703f \
&&make\
&&./updategeoip\
&&rm script/load.d/200-ASkidban.lua\
&&rm script/load.d/2000-serverexec.lua \
&&rm script/load.d/1000-sample-config.lua\
&& useradd --uid  1000 --system --no-create-home  sauer

ADD start.sh /opt/start.sh
ADD 1000-config.lua /opt/spaghettimod/script/load.d/1000-config.lua
ADD 200-auth.lua /opt/spaghettimod/script/load.d/200-auth.lua
ADD rcs_pseudomaster /opt/rcs_pseudomaster

RUN chmod +x /opt/start.sh&&mkdir -p /opt/script&&mkdir -p /opt/packages&&chown -Rvf sauer:sauer /opt/ 

USER sauer

ENTRYPOINT  [ "/opt/start.sh" ]