--[[

  This is the configuration I use on my server.

]]--

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

--make sure you delete the next two lines, or I'll have admin on your server.
cs.serverauth = os.getenv("AUTH_DOMAIN")


spaghetti.addhook(server.N_SETMASTER, L"_.skip = _.skip or (_.mn ~= _.ci.clientnum and _.ci.privilege < server.PRIV_ADMIN)")

cs.lockmaprotation = 2
cs.maprotationreset()

local rcs = require"std.rcs"

local monomaps = os.getenv("MAPS")
monomaps = map.uv(function(maps)
  local t = map.f(I, maps:gmatch("[^ ]+"))
  for i = 2, #t do
    local j = math.random(i)
    local s = t[j]
    t[j] = t[i]
    t[i] = s
  end
  return t
end, monomaps)

local MODE1=os.getenv("MODE1")
local MODE2=os.getenv("MODE2")
local MODE3=os.getenv("MODE3")

cs.maprotation(MODE1, table.concat(monomaps, " "),MODE2, table.concat(monomaps, " "),MODE3, table.concat(monomaps, " "))

local needscfg = L"_2, { needcfg = not not io.open('packages/base/' .. _2 .. '.cfg') }"
local maps = map.im(needscfg, table.sort(monomaps))


local maplist_gui = ([[
reissenfu_maps_makegui = [
  newgui (concatword reissenfu_maps_ $arg1) [
    guilist [
      guistrut 0 0
      guilist [ guistrut 0 0; looplist curmap [@@@@arg2] [
          guibutton $curmap (concat @@@@arg1 $curmap) "cube"
        ]
      ]
    ]
  ] (unescape [@arg1 maps])
  showgui (concatword reissenfu_maps_ $arg1)
]
newgui reissenfu_modelist [
  guilist [
    guilist [
      guibutton "MODE1" "mode 11; reissenfu_maps_makegui MODE1 [MAPS]"
      guibutton "MODE2" "mode 12; reissenfu_maps_makegui MODE2 [MAPS]"
      guibutton "MODE3" "mode 17; reissenfu_maps_makegui MODE3 [MAPS]"
    ]
  ]
] "Map Vote"
showgui reissenfu_modelist
]]):gsub("MODE1", MODE1):gsub("MODE2", MODE2):gsub("MODE3", MODE3):gsub("MAPS", table.concat(monomaps, " ")):gsub("  +", " ")

spaghetti.addhook(server.N_MAPVOTE, L"_.reqmode = _.reqmode ~= 1 and _.reqmode or server.gamemode")

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

server.mastermask = server.MM_PUBSERV + server.MM_AUTOAPPROVE

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
abuse.ratelimit(server.N_CLIENTPING, 4.5) --no message as it could be cause of network jitter
abuse.ratelimit(server.N_SERVCMD, 0.5, 10, L"nil, 'Yes I\\'m filtering this too.'")

--prevent masters from annoying players
local tb = require"utils.tokenbucket"
local function bullying(who, victim)
  local t = who.extra.bullying or {}
  local rate = t[victim.extra.uuid] or tb(1/30, 6)
  t[victim.extra.uuid] = rate
  who.extra.bullying = t
  return not rate()
end
spaghetti.addhook(server.N_SETTEAM, function(info)
  if info.skip or info.who == info.sender or not info.wi or info.ci.privilege == server.PRIV_NONE then return end
  local team = engine.filtertext(info.text):sub(1, engine.MAXTEAMLEN)
  if #team == 0 or team == info.wi.team then return end
  if bullying(info.ci, info.wi) then
    info.skip = true
    playermsg("...", info.ci)
  end
end)
spaghetti.addhook(server.N_SPECTATOR, function(info)
  if info.skip or info.spectator == info.sender or not info.spinfo or info.ci.privilege == server.PRIV_NONE or info.val == (info.spinfo.state.state == engine.CS_SPECTATOR and 1 or 0) then return end
  if bullying(info.ci, info.spinfo) then
    info.skip = true
    playermsg("...", info.ci)
  end
end)

--ratelimit just gobbles the packet. Use the selector to add a tag to the exceeding message, and append another hook to send the message
local function warnspam(packet)
  if not packet.ratelimited or type(packet.ratelimited) ~= "string" then return end
  playermsg(packet.ratelimited, packet.ci)
end
map.nv(function(type) spaghetti.addhook(type, warnspam) end,
  server.N_TEXT, server.N_SAYTEAM, server.N_SWITCHNAME, server.N_MAPVOTE, server.N_SPECTATOR, server.N_MASTERMODE, server.N_AUTHTRY, server.N_AUTHKICK, server.N_CLIENTPING
)

--#cheater command
local home = os.getenv("HOME") or "."
-- local function ircnotify(args)
--   --I use ii for the bots
--   local cheaterchan, pisto = io.open(home .. "/irc/cheaterchan/in", "w"), io.open(home .. "/irc/ii/pipes/pisto/in", "w")
--   for ip, requests in pairs(args) do
--     local str = "#cheater" .. (requests.ai and " \x02through bots\x02" or "") .. " on pisto.horse 1111"
--     if requests.total > 1 then str = str .. " (" .. requests.total .. " reports)" end
--     str = str .. ": "
--     local names
--     for cheater in pairs(requests.cheaters) do str, names = str .. (names and ", \x02" or "\x02") .. engine.encodeutf8(cheater.name) .. " (" .. cheater.clientnum .. ")\x02", true end
--     if not names then str = str .. "<disconnected>" end
--     if cheaterchan then cheaterchan:write(str .. ", auth holders please help!\n") end
--     if pisto then pisto:write(str .. " -- " .. tostring(require"utils.ip".ip(ip)) .. "\n") end
--   end
--   if cheaterchan then cheaterchan:close() end
--   if pisto then pisto:close() end
-- end

-- abuse.cheatercmd(ircnotify, 20000, 1/30000, 3)
-- local sound = require"std.sound"
-- spaghetti.addhook(server.N_TEXT, function(info)
--   if info.skip then return end
--   local low = info.text:lower()
--   if not low:match"cheat" and not low:match"hack" and not low:match"auth" and not low:match"kick" then return end
--   local tellcheatcmd = info.ci.extra.tellcheatcmd or tb(1/30000, 1)
--   info.ci.extra.tellcheatcmd = tellcheatcmd
--   if not tellcheatcmd() then return end
--   playermsg("\f2Problems with a cheater? Please use \f3#cheater [cn|name]\f2, and operators will look into the situation!", info.ci)
--   sound(info.ci, server.S_HIT, true) sound(info.ci, server.S_HIT, true)
-- end)

require"std.enetping"

local parsepacket = require"std.parsepacket"
spaghetti.addhook("martian", function(info)
  if info.skip or info.type ~= server.N_TEXT or info.ci.connected or parsepacket(info) then return end
  local text = engine.filtertext(info.text, true, true)
  engine.writelog(("limbotext: (%d) %s"):format(info.ci.clientnum, text))
  info.skip = true
end, true)

--simple banner

local commands = require"std.commands"

local git = io.popen("echo `git rev-parse --short HEAD` `git show -s --format=%ci`")
local gitversion = git:read()
git = nil, git:close()
commands.add("info", function(info)
  playermsg("spaghettimod is a reboot of hopmod for programmers. Will be used for SDoS.\nKindly brought to you by pisto." .. (gitversion and "\nCommit " .. gitversion or ""), info.ci)
end)

local fence, sendmap = require"std.fence", require"std.sendmap", require"std.maploaded"

banner = "This server uses pisto's RCS and spaghettimod.\n Use \f0#votemap\f7 to display a list of available maps."
spaghetti.addhook("maploaded", function(info) info.ci.extra.mapcrcfence = fence(info.ci) end)
spaghetti.later(60000, L"server.sendservmsg(banner)", true)

commands.add("rcs", function(info) playermsg(
"\f1Remote CubeScript\f7 (\f1rcs\f7) allows the server to run cubescript code on your client (like the \f2crapmod.net\f7 master server).\n" ..
"\f1rcs\f7 provides a way to use auto-downloaded maps in ctf and capture modes, and run the map cfg file.\n" ..
"\f1rcs\f7 requires a one-time installation with these commands: \f0/mastername pisto.horse; updatefrommaster\f7\n" ..
"For detailed information visit \f0pisto.horse/rcs\f7 . You can uninstall \f1rcs\f7 any time by typing \f0/rcs_uninstall"
, info.ci) end)

commands.add("votemap", function(info)
  if not info.ci.extra.rcs then 
    local msg = "\f0Available maps\f7: " .. table.concat(monomaps, ", ")
    playermsg(msg, info.ci)
  else
    rcs.send(info.ci, maplist_gui)
  end
end, "#votemap : show the list of maps that can be played and voted on this server.")


spaghetti.later(1000, function()
    for ci in iterators.clients() do
        if ci.extra.rcs_first_check == nil then
            ci.extra.rcs_first_check=true
        else
            if not ci.extra.rcs  then 
                txt="\f3~~ RCS is not available ~~\f7\nThis server requires a special client side plugin to properly load the maps.\nPlease use this chat command \f0/mastername "..os.getenv("MASTER_IP")..";updatefrommaster\f7 and \f0/reconnect\f7 to this server to complete the installation.\n"..
                "Your master server will be reset to its original value (\f0master.sauerbraten.org\f7) after the process."
                engine.writelog("RCS not available for "..server.colorname(ci, nil))
                playermsg(txt, ci)    
            end
        end
     
    end
  end,true)

local function trysendmap(ci, force)
  if not maps[server.smapname] or server.m_edit or not sendmap.hasmap() then return end
  if not force and ci.mapcrc % 2^32 == server.mcrc then server.sendservmsg(server.colorname(ci, nil) .. " \f0has this map already\f7.") return end
  local extra = ci.extra

  
--   if not server.m_teammode then
--     engine.writelog("sending map to " .. server.colorname(ci, nil) .. " with coopedit" .. (extra.rcs and " and rcs" or ""))
--     sendmap.forcecurrent(ci, true, true, true)
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
