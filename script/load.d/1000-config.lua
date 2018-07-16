--[[

  This is the configuration I use on my server.

]]--
require"std.mapbattle"

engine.writelog("Applying the new maps configuration.")

local servertag = require"utils.servertag"
servertag.tag = os.getenv("SERVER_TAG")

local uuid = require"std.uuid"

local fp, L = require"utils.fp", require"utils.lambda"
local map, range, fold, last, I = fp.map, fp.range, fp.fold, fp.last, fp.I
local abuse, playermsg = require"std.abuse", require"std.playermsg"
local iterators=require"std.iterators"

cs.maxclients = os.getenv("MAX_PLAYERS")
cs.serverport = os.getenv("SERVER_PORT")
cs.serverauth = os.getenv("AUTH_DOMAIN")

spaghetti.later(10000, L'engine.requestmaster("\\n")', true)
spaghetti.addhook("masterin", L'if _.input:match("^failreg") then engine.lastupdatemaster = 0 end', true)

cs.lockmaprotation = 2
cs.maprotationreset()

spaghetti.addhook(server.N_SETMASTER, L"_.skip = _.skip or (_.mn ~= _.ci.clientnum and _.ci.privilege < server.PRIV_AUTH)")

local rcs = require"std.rcs"

local maplist = os.getenv("MAPS")
maplist = map.uv(function(maps)
  local t = map.f(I, maps:gmatch("[^ ]+"))
  for i = 2, #t do
    local j = math.random(i)
    local s = t[j]
    t[j] = t[i]
    t[i] = s
  end
  return t
end, maplist)

local MODE=os.getenv("MODE")


cs.maprotation(MODE, table.concat(maplist, " "))

local needscfg = L"_2, { needcfg = not not io.open('packages/base/' .. _2 .. '.cfg') }"
local maps = map.im(needscfg, table.sort(maplist))



local maplist_part1="";
local maplist_part2="";
local maplist_part3="";

local maplist_size=0;
for mpi in string.gmatch(os.getenv("MAPS"), "%S+") do
  maplist_size=maplist_size+1
end

local maps_per_part=maplist_size/3;
local selected_part=0;
local part_i=0;

for mpi in string.gmatch(os.getenv("MAPS"), "%S+") do
  if part_i > maps_per_part and selected_part<3 then
    selected_part=selected_part+1
    part_i=0
  end
  part_i=part_i+1
  if(selected_part==0) then
    if maplist_part1 ~= "" then
      maplist_part1=maplist_part1.." "
    end
    maplist_part1=maplist_part1..mpi
  elseif selected_part==1 then
    if maplist_part2 ~= "" then
      maplist_part2=maplist_part2.." "
    end
    maplist_part2=maplist_part2..mpi
  else
    if maplist_part3 ~= "" then
      maplist_part3=maplist_part3.." "
    end
    maplist_part3=maplist_part3..mpi
  end
end


local maplist_gui = ([[
  rcs_swmaps = "MAPS1"
  rcs_swmaps2 = "MAPS2"
  rcs_swmaps3 = "MAPS3"
  
  rcs_genmapitems = [
    looplist curmap $arg1 [
        guibutton $curmap (concat map $curmap) "cube"
    ]
]

rcs_showmapshot = [ 
    guibar
    guiimage (concatword "packages/base/" (if (> $numargs 0) [result $arg1] [at $guirollovername 0]) ".jpg") $guirolloveraction 4 1 "data/cube.png"
]

newgui rcs_votemap [
    guilist [
      guistrut 10 1
      guilist [ guistrut 10 1; rcs_genmapitems $rcs_swmaps ]
      guilist [ guistrut 10 1; rcs_genmapitems $rcs_swmaps2 ]
      guilist [ guistrut 10 1; rcs_genmapitems $rcs_swmaps3 ]
      rcs_showmapshot
    ]
] "Vote Map"

showgui rcs_votemap
]]):gsub("MAPS1", maplist_part1):gsub("MAPS2", maplist_part2):gsub("MAPS3", maplist_part3):gsub("  +", " ")


local ents, putf, n_client = require"std.ents", require"std.putf", require"std.n_client"
local function quirk_replacemodels(replacements)
  replacements = replacements or {}
  return function(ci)
    if not ents.active() then return end
    local p
    for i, _, ment in ents.enum(server.MAPMODEL) do
      if replacements[ment.attr2] then p = putf(p or {15, r=1}, server.N_EDITENT, i, ment.o.x * server.DMF, ment.o.y * server.DMF, ment.o.z * server.DMF, server.MAPMODEL, ment.attr1, replacements[ment.attr2], 0, 0, 0)
      else p = putf(p or {15, r=1}, server.N_EDITENT, i, 0, 0, 0, server.NOTUSED, 0, 0, 0, 0, 0) end
    end
    return p and engine.sendpacket(ci.clientnum, 1, n_client(p, ci):finalize(), -1)
  end
end
local function quirk_extrarcs(cs)
  return function(ci) return ci.extra.rcs and rcs.send(ci, cs) end
end
local function quirk_multi(quirks)
  return function(ci) for _, f in ipairs(quirks) do f(ci) end end
end

server.mastermask = server.MM_PUBSERV + server.MM_AUTOAPPROVE + server.MM_LOCKED + server.MM_VETO

require"std.pm"

--moderation

cs.teamkillkick("*", 7, 30)

--limit reconnects when banned, or to avoid spawn wait time
abuse.reconnectspam(1/60, 5)

--limit some message types
spaghetti.addhook(server.N_KICK, function(info)
  if info.skip or info.ci.privilege > server.PRIV_MASTER then return end
  info.skip = true
  playermsg("No. Use gauth.", info.ci)
end)
spaghetti.addhook(server.N_SOUND, function(info)
  if info.skip or abuse.clientsound(info.sound) then return end
  info.skip = true
  playermsg("I know I used to do that but... whatever.", info.ci)
end)
abuse.ratelimit({ server.N_TEXT, server.N_SAYTEAM }, 0.5, 10, L"nil, 'I don\\'t like spam.'")
abuse.ratelimit(server.N_SWITCHNAME, 1/30, 4, L"nil, 'You\\'re a pain.'")
abuse.ratelimit(server.N_MAPVOTE, 1/10, 3, L"nil, 'That map sucks anyway.'")
abuse.ratelimit(server.N_SPECTATOR, 1/30, 5, L"_.ci.clientnum ~= _.spectator, 'Can\\'t even describe you.'") --self spec
abuse.ratelimit(server.N_MASTERMODE, 1/30, 5, L"_.ci.privilege == server.PRIV_NONE, 'Can\\'t even describe you.'")
abuse.ratelimit({ server.N_AUTHTRY, server.N_AUTHKICK }, 1/60, 4, L"nil, 'Are you really trying to bruteforce a 192 bits number? Kudos to you!'")
abuse.ratelimit(server.N_SERVCMD, 0.5, 10, L"nil, 'Yes I\\'m filtering this too.'")
abuse.ratelimit(server.N_JUMPPAD, 1, 10, L"nil, 'I know I used to do that but... whatever.'")
abuse.ratelimit(server.N_TELEPORT, 1, 10, L"nil, 'I know I used to do that but... whatever.'")


--ratelimit just gobbles the packet. Use the selector to add a tag to the exceeding message, and append another hook to send the message
local function warnspam(packet)
  if not packet.ratelimited or type(packet.ratelimited) ~= "string" then return end
  playermsg(packet.ratelimited, packet.ci)
end
map.nv(function(type) spaghetti.addhook(type, warnspam) end,
  server.N_TEXT, server.N_SAYTEAM, server.N_SWITCHNAME, server.N_MAPVOTE, server.N_SPECTATOR, server.N_MASTERMODE, server.N_AUTHTRY, server.N_AUTHKICK, server.N_CLIENTPING
)

require"std.enetping"

local parsepacket = require"std.parsepacket"
spaghetti.addhook("martian", function(info)
  if info.skip or info.type ~= server.N_TEXT or info.ci.connected or parsepacket(info) then return end
  local text = engine.filtertext(info.text, true, true)
  engine.writelog(("limbotext: (%d) %s"):format(info.ci.clientnum, text))
  info.skip = true
end, true)


local commands = require"std.commands"

local git = io.popen("echo `git rev-parse --short HEAD` `git show -s --format=%ci`")
local gitversion = git:read()
git = nil, git:close()
commands.add("info", function(info)
  playermsg("spaghettimod is a reboot of hopmod for programmers. Will be used for SDoS.\nKindly brought to you by pisto." .. (gitversion and "\nCommit " .. gitversion or ""), info.ci)
end)

local fence, sendmap = require"std.fence", require"std.sendmap", require"std.maploaded"

banner = "Use \f1#votemap\f7 to display a list of available maps."
spaghetti.addhook("maploaded", function(info) info.ci.extra.mapcrcfence = fence(info.ci) end)
spaghetti.later(60000, L"server.sendservmsg(banner)", true)

spaghetti.later(30000, function()
      if server.m_collect then
        server.sendservmsg("\f6COLLECT ELI5:\f1 Kill the reds and collect their skulls. Touch the red base to steal one skull from their collection.")
      end
  end,true)


if os.getenv("USE_SWMAPPACK") ~= "" then
  swbanner="\f6Want a better experience? Download the Sauer World content pack: \f1http://bit.ly/sauerpack1"
  spaghetti.later(120000, L"server.sendservmsg(swbanner)", true)
end


commands.add("rcs", function(info) playermsg(
"\f1Remote CubeScript\f7 (\f1rcs\f7) allows the server to run cubescript code on your client (like the \f2crapmod.net\f7 master server).\n" ..
"\f1rcs\f7 provides a way to use auto-downloaded maps in ctf and capture modes, and run the map cfg file.\n" ..
"\f1rcs\f7 requires a one-time installation with these commands: \f0/mastername "..os.getenv("MASTER_IP").."; updatefrommaster\f7\n" ..
"For detailed information visit \f0pisto.horse/rcs\f7 . You can uninstall \f1rcs\f7 any time by typing \f0/rcs_uninstall"
, info.ci) end)

commands.add("votemap", function(info)
  if not info.ci.extra.rcs then 
    local msg = "\f0Available maps\f7: " .. table.concat(maplist, ", ")
    playermsg(msg, info.ci)
  else
    rcs.send(info.ci, maplist_gui)
  end
end, "#votemap : show the list of maps that can be played and voted on this server.")


spaghetti.later(100, function()
    for ci in iterators.clients() do
        if ci.extra.nchecks ==nil then
            ci.extra.nchecks=0
        elseif ci.extra.nchecks < 20 then
            ci.extra.nchecks=ci.extra.nchecks+1
        elseif ci.extra.nchecks < 1200 then
            ci.extra.nchecks=ci.extra.nchecks+1
            if not ci.extra.rcs  then 
                txt="\f7~~ RCS is not available ~~\f3\nTHIS SERVER REQUIRES A SPECIAL CLIENT SIDE CUBESCRIPT TO PROPERLY LOAD THE MAPS.\nPLEASE USE THIS CHAT COMMAND \f0/mastername "..os.getenv("MASTER_IP")..";updatefrommaster\f3 TO DOWNLOAD THE SCRIPT AND \f0/reconnect\f3 TO THIS SERVER.\n"..
                "YOUR MASTER SERVER WILL BE RESET TO ITS ORIGINAL VALUE (\f0master.sauerbraten.org\f3) AFTER THE PROCESS."
                playermsg(txt, ci)    
            end
        end
     
    end
  end,true)

local function trysendmap(ci, force)
  if not maps[server.smapname] or server.m_edit or not sendmap.hasmap() then return end
  if not force and ci.mapcrc % 2^32 == server.mcrc then server.sendservmsg(server.colorname(ci, nil) .. " \f0has this map already\f7.") return end
  local extra = ci.extra
  if extra.rcs then
    engine.writelog("sending map to " .. server.colorname(ci, nil) .. " with savemap")
    sendmap.forcecurrent(ci, false, true, maps[server.smapname].cfgcopy)
  else return end
  server.sendservmsg(server.colorname(ci, nil) .. " \f2is downloading the map\f7...")
end

spaghetti.addhook("fence", function(info)
  local ci = info.ci
  local extra = ci.extra
  if extra.mapcrcfence ~= info.fence then return end
  trysendmap(ci)
end)

spaghetti.addhook("rcshello", function(info)
  local ci = info.ci
  if not ci.extra.rcsspam then return end
  playermsg("\f1Remote CubeScript\f7 detected! Maps will be sent automatically.", ci)
  trysendmap(ci, true)
end)

spaghetti.addhook(server.N_SPECTATOR, function(info)
  if info.skip or not info.spinfo or info.spinfo.clientnum ~= info.ci.clientnum and info.ci.privilege == server.PRIV_NONE then return end
  info.spinfo.extra.wantspec = info.val == 1
end)

spaghetti.addhook("sendmap", function(info)
  local ci = info.ci
  server.sendservmsg(server.colorname(ci, nil) .. " \f0downloaded the map\f7.")
  if not ci.extra.firstspam then
    local ciuuid = ci.extra.uuid
    spaghetti.later(1000, function()
      local ci = uuid.find(ciuuid)
      return ci and playermsg(banner, ci)
    end)
    ci.extra.firstspam = true
  end
  if (not info.rcs or info.method == "savemap") and maps[server.smapname].nocfgquirk then maps[server.smapname].nocfgquirk(ci) end
  if ci.extra.wantspec or ci.state.state ~= engine.CS_SPECTATOR or ci.privilege == server.PRIV_NONE and server.mastermode >= server.MM_LOCKED then return end
  server.unspectate(ci)
  server.sendspawn(ci)
end)

--lazy fix all bugs.
spaghetti.addhook("noclients", function()
  if engine.totalmillis >= 24 * 60 * 60 * 1000 then reboot, spaghetti.quit = true, true end
end)