#!/usr/bin/env lua
--[[
   Copyright 2016 Semyon Yakimov

   This file is part of RogainingRoutes.

   RogainingRoutes is free software: you can redistribute it and/or modify
   it under the terms of the GNU General Public License as published by
   the Free Software Foundation, either version 3 of the License, or
   (at your option) any later version.

   RogainingRoutes is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.

   You should have received a copy of the GNU General Public License
   along with RogainingRoutes.  If not, see <http://www.gnu.org/licenses/>.
--]]


--! Configuration

local mapFileName = "map.png"
local cpFileName = "checkpoints.txt"
local splitsFileName = "splits.htm"
local group = "Мужчины-24"
local start_time = "12:00:00"
local members = 2
local metersInPixel = 10.3985
local rotateAngle = 19.5 ---< in degrees
local start = {}
start.x = 655 
start.y = 448

---

function timeToSec(str)
   local _,_,hour,min,sec= str:find("^(%d+):(%d+):(%d+)")
   if not hour then
      _,_,min,sec= str:find("^(%d+):(%d+)")
      hour = 0
   end
   if sec and min and hour then
      return sec + min * 60 + hour * 3600
   end
end

start_time = timeToSec(start_time)

function secToTime(sec)
   local hour = math.floor(sec/3600)
   sec = sec - hour*3600
   local min = math.floor(sec/60)
   sec = sec - min*60
   if hour > 23 then
      hour = hour - 24
   end
   return string.format("%d:%02d:%02d",hour,min,sec)
end

function degToRadian(angle)
   return angle * math.pi / 180
end

local rotateRadians = degToRadian(rotateAngle)

function rotate(x,y,radians)
   local retX = x * math.cos(radians) - y * math.sin(radians)
   local retY = x * math.sin(radians) + y * math.cos(radians)
   return retX, retY
end

function run(cmd)
   local ret,err = io.popen(cmd,"r")
   if not ret then
      print("No output from ",cmd)
      return
   end

   for line in ret:lines() do
      if line and line ~= "" then
         print(line)
      end
   end
   ret:close()
end

local checkPoints = {}

--[[
for line in io.lines(cpFileName) do
   local _,_,cp,x,y = string.find(line,"^(%d+)%s([%d%-]+)%s([%d%-]+)$")
   if cp then
      local _x = tonumber(x)
      local _y = -tonumber(y)
      checkPoints[cp] = {}
      checkPoints[cp].xM = _x
      checkPoints[cp].yM = _y
      _x = _x / metersInPixel
      _y = _y / metersInPixel
      _x, _y = rotate(_x,_y,rotateRadians)
      checkPoints[cp].x = _x + start.x
      checkPoints[cp].y = _y + start.y
   end
end
]]

function drawRoute(commandCps,cmd)
   if group then
      run(string.format('dir=%s; if [ ! -d $dir ]; then mkdir $dir; fi',group))
   end
   local outFileName = string.format('./%s/%s-%s-%s.png',group,cmd.placement,cmd.number,removeSpaces(cmd.name))
   local str = ""
   for _,cp in ipairs(commandCps) do
      str = str .. checkPoints[cp].x ..','.. checkPoints[cp].y ..' '
   end

local annotation = string.format("Команда\n    %s\n    %s\n    %s\nМесто\n    %s\nРезультат\n    %s\nВремя\n    %s\nДлина по прямым\n    %.2f км\nОчков на километр\n    %.2f",cmd.number..'. '..cmd.name,cmd.member1,cmd.member2 or '',cmd.placement..' ('..group..')',cmd.result,cmd.timeout,cmd.len,cmd.result/cmd.len)
   --run(string.format("convert %s -gravity SouthEast -page +200+0 -background white -mosaic -fill none -stroke blue -strokewidth 2 -draw 'polyline %d,%d %s' %s",mapFileName,start.x,start.y,str,outFileName))
   run(string.format("convert %s -gravity SouthEast -splice +0+0 -background white -chop 250x1414 -fill none -stroke blue -strokewidth 2 -draw 'polyline %d,%d %s' -font Arial-Курсив -fill blue -pointsize 40 -gravity NorthWest -draw \"text 1020,50 '%s'\" %s",mapFileName,start.x,start.y,str,annotation,outFileName))
end

function fromCSV(s)
   local c = string.sub(s,string.len(s))
   if c ~= ';' then
      s = s .. ';'
   end
   local t = {}        -- table to collect fields
   local fieldstart = 1
   repeat
      -- next field is quoted? (start with `"'?)
      if string.find(s, '^"', fieldstart) then
        local a, c
        local i  = fieldstart
        repeat
           -- find closing quote
           a, i, c = string.find(s, '"("?)', i+1)
        until c ~= '"'    -- quote not followed by quote?
        if not i then error('unmatched "') end
        local f = string.sub(s, fieldstart+1, i-1)
        table.insert(t, (string.gsub(f, '""', '"')))
        fieldstart = string.find(s, ';', i) + 1
      else                -- unquoted; find next comma
         local nexti = string.find(s, ';', fieldstart)
         table.insert(t, string.sub(s, fieldstart, nexti-1))
         fieldstart = nexti + 1
      end
   until fieldstart > string.len(s)
   return t
end

function removeSpaces(s)
   return string.gsub(s,' ','-')
end

function getCommandNumber(s)
   local _,_,ret = string.find(s,'^(%d+)%.%d')
   return ret
end

local checked = {}
function isChecked(cmdNum)
   for i=#checked,1 do
      if cmdNum == checked[i] then
         return true
      end
   end
   return false
end

local lastCmd = {}
function handleLine(line)
   local t = fromCSV(line)
   local cmd = {}
   cmd.number = getCommandNumber(t[2])
   cmd.member1 = t[4]..' '..t[3]
   cmd.name = t[5]
   cmd.result = t[7]
   cmd.timeout = t[8]
   cmd.placement = t[9]
   if members == 2 then
      if cmd.number == lastCmd.number then
         cmd.member2 = lastCmd.member1
      end
      lastCmd = cmd
   end
   
   if tonumber(cmd.placement) < 10 then
      cmd.placement = '0'..tostring(cmd.placement)
   end
   local route = {}
   local lastCpCoords = {}
   lastCpCoords.x = 0
   lastCpCoords.y = 0
   local len = 0
   for i = 10,#t do
      local _,_,cpNum = string.find(t[i],'%[(%d+)%]')
      if cpNum then
         table.insert(route,cpNum)
         local x = checkPoints[cpNum].xM
         local y = checkPoints[cpNum].yM
         len = len + math.sqrt((x - lastCpCoords.x)^2 + (y - lastCpCoords.y)^2)
         lastCpCoords.x = x
         lastCpCoords.y = y
      end
   end
   len = len + math.sqrt((0 - lastCpCoords.x)^2 + (0 - lastCpCoords.y)^2)
   
   cmd.len = len / 1000
   drawRoute(route,cmd)
end

local title = ""

function makeTeamHtml(team)
   local function teamTbl()
      local str = ""
      for i,v in ipairs(team.route) do
         print(i,v.id)
         str = str.."<tr>"
         str = str.."<td>"..v.id.."</td>"
         str = str.."<td>"..v.time.."</td>"
         str = str.."<td>"..v.split.."</td>"
         str = str.."<td></td>"
         str = str.."<td></td>"
         str = str.."<td></td>"
         str = str.."</tr>\n"
      end
      str = str .. "<tr><th>&nbsp;</th><th>"..team.time.."</th><th>&nbsp;</th><th>"..team.result.."</th><th>len км</th><th><strong>sp мин/км</strong></th></tr>"
      return str
   end
   local team_html = [[
<html><head><meta http-equiv="Content-Type" content="text/html; charset=utf-8">
<style>
body {font-family: "Arial Narrow"; font-size: 10pt;}
table {font-family: "Arial Narrow"; font-size: 10pt; border:1px solid #AA0055; background: #DDDDAA;text-align: center;}
table td{ margin:O; padding: 0 2px; background: #FFFFFF;}
.rezult th { font-family: "Arial Narrow";font-style: italic; font-size: 10pt;color: #AA0055;padding: 2px 3px; background: #EEEEBB;}
H1  {font-size: 14pt;font-weight: bold;color: #AA0055;text-align: left;}
.yl, tr.yl td {background: #FFFFAA;}
</style>
<title>]]..title..[[</title>
</head>
<body>
<h1>График движения команды №]]..team.id.." "..team.name.." ("..team.second_name.." "..team.first_name..[[)</h1>
<table>
<tr><th>КП</th><th>Время</th><th>Сплит</th><th>Очки</th><th>Расстояние (км)</th><th>Скорость (мин/км)</th></tr>
]]..teamTbl(team)..
[[</table><br>
<canvas id="e" width="1200" height="846"></canvas>
<script>
var kp_list = [ [-37.682621152963,88.178141223889, "rgb(224,0,62)"],[33.246734052268,138.9698643235, "rgb(255,124,0)"],[180.87718210406,195.55901461462, "rgb(255,62,0)"],[277.00257784591,306.14715879549, "rgb(255,224,0)"],[402.00732781358,180.83974950794, "rgb(255,256,0)"],[308.38933837824,123.56418008532, "rgb(204,0,102)"],[194.97707140447,-29.888142510114, "rgb(255,248,0)"],[91.260427247149,-33.153961737027, "rgb(255,192,0)"],[44.451940829338,-63.770250623801, "rgb(255,220,0)"],[80.855216971534,-147.30907564722, "rgb(255,210,0)"],[146.03865049667,-151.26643540435, "rgb(170,0,170)"],[264.51880493588,-163.84143234645, "rgb(255,150,0)"],[370.03460555934,-144.71285147047, "rgb(255,176,0)"],[344.494971314,-229.35321025571, "rgb(127,0,256)"],[210.90423151532,-279.44335827926, "rgb(159,0,192)"],[147.15537992571,-271.54623343836, "rgb(159,0,192)"],[6.7052458202325,-268.69392853459, "rgb(255,30,0)"],[-71.817864912021,-270.16742066676, "rgb(186,0,138)"],[-171.20343815739,-298.64377106811, "rgb(155,0,200)"],[-222.71142376999,-233.82500065405, "rgb(228,0,54)"],[-284.32749876714,-145.96818222339, "rgb(228,0,54)"],[-50.581639616175,-198.85180118398, "rgb(202,0,106)"],[-34.388896172877,-122.86271170794, "rgb(201,0,108)"],[0.093530421142196,-0.13601196055146, "rgb(161,0,188)"],];
var canvas = document.getElementById("e");
var context = canvas.getContext("2d");
var map = new Image();
var c = [732.53574555004, 321.79749051649];
map.src = "map.jpg";
map.onload = function() {
	context.drawImage(map, 0, 0);
	for (i=0, l=kp_list.length; i<l; i++) {
		context.beginPath();
		context.arc(c[0] + kp_list[i][0], c[1] + kp_list[i][1], 4, 0, Math.PI * 2, false);
		context.closePath();
		context.strokeStyle = "#f00";
		context.stroke();
		context.fillStyle = "#f00";
		context.fill();
	}
	context.lineWidth = 3;
	var old_x = 0, old_y = 0;
	for (i=0, l=kp_list.length; i<l; i++) {
		context.beginPath();
		context.moveTo(c[0] + old_x, c[1] + old_y);
		context.lineTo(c[0] + kp_list[i][0], c[1] + kp_list[i][1]);
		context.strokeStyle = kp_list[i][2];
		context.stroke();
		old_x = kp_list[i][0]; old_y = kp_list[i][1];
	}
};
</script>
</body></html>
]]
   local team_file = io.open(team.id .. ".html","w")
   team_file:write(team_html)
   team_file:close()
end

local field_name_by_index = {
   "number",
   "id",
   "second_name",
   "first_name",
   "name",
   "result",
   "time",
   "position",
   "subgroup",
   "_"
}

function parseTeamSplits(team_data)
   local team = {}
   team.route = {}
   for i,v in ipairs(team_data) do
      if (v.xml == "td") then
         if v[1] == nil then
            break
         end
         if field_name_by_index[i] then
            team[field_name_by_index[i]] = v[1]
         else
            local cp = {}
            _,_,cp.time,cp.id = string.find(v[1],'^(%d+:%d+)%[(%d+)%]')
            _,_,cp.split = string.find(v[1],'(%d+:%d+)$')
            if cp.split == nil then
               cp.split = cp.time
            end
            local time = timeToSec(cp.time)
            time = time + start_time
            cp.time = secToTime(time)
            table.insert(team.route,cp)
         end
      end
   end
   return team
end

local teams = {}
function parseSplitsTable(html_data)
   for i,v in ipairs(html_data) do
      if (v.xml == "tr" and i ~= 1) then
         table.insert(teams, parseTeamSplits(v))
      end
   end
end

local xml = require "xml" -- sudo luarocks install xml

local file = io.open(splitsFileName)
local docstr = file:read("*a")
file:close()

docstr = docstr:gsub("<meta.->","")
docstr = docstr:gsub("<style>.-</style>","")
docstr = docstr:gsub("<nobr>","")
docstr = docstr:gsub("<br>","")
docstr = "<document>"..docstr.."</document>"

local splits_data = xml.load(docstr)

title = xml.find(splits_data,"title")[1]

for i,v in ipairs(splits_data) do
   if (v.xml == 'h2' and v[1] == group) then
      if (splits_data[i+1].xml == "table") then
         parseSplitsTable(splits_data[i+1])
         break
      end
   end
end

--print(teams[1].id)
--print(teams[1].second_name)
for i,v in ipairs(teams[1].route) do
   --print(v.id)
end
makeTeamHtml(teams[1])

