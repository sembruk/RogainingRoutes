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
local cpFileName = "/home/sem/mega/routes/coordinates.xml"
local splitsFileName = "/home/sem/mega/routes/splits.htm"
local group = "Мужчины-24"
local start_time = "12:00:00"
local metersInPixel = 9.8778
local k = 35/1000
local rotateAngle = 0 ---< in degrees
local start = {
   x = 1069,
   y = 1719,
}

---

local image = {}

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

local start_secs = timeToSec(start_time)

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

function secToSplit(sec)
   local hour = math.floor(sec/3600)
   sec = sec - hour*3600
   local min = math.floor(sec/60)
   sec = sec - min*60
   if hour == 0 then
      return string.format("%02d:%02d",min,sec)
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

function run(cmd, act)
   local ret,err = io.popen(cmd,"r")
   if not ret then
      print("No output from ",cmd)
      return
   end

   for line in ret:lines() do
      if line and line ~= "" then
         if act then
            act(line)
         else
            print(line)
         end
      end
   end
   ret:close()
end

run("identify map.jpg", function(str)
   local _,_,w,h = str:find('(%d+)x(%d+)')
   image.width = w
   image.height = h
end)

local title = ""

function makeTeamHtml(team, cps)
   local function teamTbl()
      local previos = {
         x = 0,
         y = 0,
      }
      local str = "<tr><td>С</td><td>"..start_time.."</td><td></td><td></td><td></td><td></td></tr>\n"
      local sum_len = 0
      team.sum = 0
      for i,v in ipairs(team.route) do
         local x,y
         if tonumber(v.id) then
            team.sum = team.sum + v.local_points
            x = cps[v.id].x
            y = cps[v.id].y
         else
            x = 0
            y = 0
         end

         local len =  math.sqrt((x - previos.x)^2 + (y - previos.y)^2)
         len = len / 1000 -- km
         sum_len = sum_len + len
         previos.x = x
         previos.y = y

         str = str.."<tr>"
         str = str.."<td>"..v.id.."</td>"
         str = str.."<td>"..v.time.."</td>"
         str = str.."<td>"..v.split.."</td>"
         if tonumber(v.id) then
            str = str.."<td>"..v.local_points.." / "..team.sum.."</td>"
         else
            str = str.."<td></td>"
         end
         str = str.."<td>"..string.format("%.2f / %.2f",len,sum_len).."</td>"
         str = str.."<td>"..string.format("%.2f",timeToSec(v.split)/len/60).."</td>"
         str = str.."</tr>\n"
      end
      str = str .. "<tr><th>&nbsp;</th><th>&nbsp;</th><th>"..team.time..
      "</th><th>"..team.result.."</th><th>"..string.format("%.2f км",sum_len)..
      "</th><th><strong>"..string.format("%.2f",timeToSec(team.time)/sum_len/60).." мин/км</strong></th></tr>\n"
      local sum_len = sum_len + math.sqrt((0 - previos.x)^2 + (0 - previos.y)^2)
      return str
   end

   local team_tbl = teamTbl()

   local cp_list = 'var cp_list = [ '
   for i,v in ipairs(team.route) do
      if tonumber(v.id) then
         local x_p = math.floor(cps[v.id].x / metersInPixel)
         local y_p = math.floor(cps[v.id].y / metersInPixel)
         cp_list = cp_list ..'['..x_p..','..y_p..'],'
      end
   end
   cp_list = cp_list..'[0,0] ];'

   local team_html = [[
<html><head><meta http-equiv="Content-Type" content="text/html; charset=utf-8">
<style>
body {font-family: "Arial Narrow"; font-size: 10pt;}
table {font-family: "Arial Narrow"; font-size: 10pt; border:1px AA0055; background: #ddd;text-align: center;}
table td{ margin:O; padding: 0 2px; background: #FFFFFF;}
.rezult th { font-family: "Arial Narrow";font-style: italic; font-size: 10pt;color: #AA0055;padding: 2px 3px; background: #EEEEBB;}
H1  {font-size: 14pt;font-weight: bold;text-align: left;}
.yl, tr.yl td {background: #FFFFAA;}
</style>
<title>]]..team.id.."."..team.name..[[</title>
</head>
<body>
<h1>]]..title..[[</h1>
<table>
<tr><td>Команда</td><td>]]..team.id.."."..team.name..[[</td></tr>
<tr><td>Участники</td><td>]]..team.second_name..", "..team.first_name..[[</td></tr>
<!--<tr><td>Город</td><td>]]..[[</td></tr>-->
<tr><td>Место</td><td>]]..team.position..[[</td></tr>
<tr><td>Очки</td><td>]]..team.sum..[[</td></tr>
<tr><td>Штраф</td><td>]]..(team.sum-team.result)..[[</td></tr>
<tr><td>Время</td><td>]]..team.time..[[</td></tr>
<tr><td>Результат</td><td><b>]]..team.result..[[</b></td></tr>
</table>
<table>
<tr><th>КП</th><th>Время</th><th>Сплит</th><th>Очки</th><th>Расстояние (км)</th><th>Скорость (мин/км)</th></tr>
]]..team_tbl..
[[</table><br>
<canvas id="e" width="]]..image.width..[[" height="]]..image.height..[["></canvas>
<script>
]]..cp_list..
[[var canvas = document.getElementById("e");
var context = canvas.getContext("2d");
var map = new Image();
var c = []]..start.x..','..start.y..[[];
map.src = "map.jpg";
map.onload = function() {
	context.drawImage(map, 0, 0);
	for (i=0, l=cp_list.length; i<l; i++) {
		context.beginPath();
		context.arc(c[0] + cp_list[i][0], c[1] + cp_list[i][1], 3, 0, Math.PI * 2, false);
		context.closePath();
		context.strokeStyle = "#f00";
		context.stroke();
		context.fillStyle = "rgba(255,0,0,0.5)";
		context.fill();
	}
	context.lineWidth = 3;
	var old_x = 0, old_y = 0;
	for (i=0, l=cp_list.length; i<l; i++) {
		context.beginPath();
		context.moveTo(c[0] + old_x, c[1] + old_y);
		context.lineTo(c[0] + cp_list[i][0], c[1] + cp_list[i][1]);
		context.strokeStyle = "rgba(255,0,0,0.5)";
		context.stroke();
		old_x = cp_list[i][0]; old_y = cp_list[i][1];
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
   local prev_secs
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
            cp.id = tonumber(cp.id)
            if cp.split == nil then
               cp.split = cp.time
            end
            local secs = timeToSec(cp.time)
            prev_secs = secs
            secs = secs + start_secs
            cp.time = secToTime(secs)
            _,_,cp.local_points = string.find(cp.id,'^(%d+)%d$')
            table.insert(team.route,cp)
         end
      end
   end

   local finish = {}
   finish.id = "Ф"
   local secs = timeToSec(team.time)
   local split = secs - prev_secs
   secs = secs + start_secs
   finish.time = secToTime(secs)
   finish.split = secToSplit(split)
   table.insert(team.route,finish)

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

local cp_data = xml.loadpath(cpFileName)
local checkPoints = {}

for i,v in ipairs(cp_data) do
   if v.cp then
      local cp = tonumber(v.cp)
      checkPoints[cp] = {}
      checkPoints[cp].x = v.x * k
      checkPoints[cp].y = v.y * k
   end
end

makeTeamHtml(teams[1],checkPoints)
makeTeamHtml(teams[4],checkPoints)

