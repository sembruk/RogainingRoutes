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

local mapFileName = "map.jpg"
local cpFileName = "coordinates.xml"
local splitsFileName = "splits.htm"
local outDir = "./out"
local title = "Чемпионат России по рогейну на велосипедах, 08.08.2015"
local groups = {"Вело_24",}
local start_time = "12:00:00"
local metersInPixel = 9.8778
local k = 50/1000
local javascript_map_scale = 1
local rotateAngle = 0 ---< in degrees
local start = {
   x = 1251,
   y = 356,
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

local style = [[
<style>
body {font-family:"Arial Narrow"; font-size:12pt;}
table {text-align:center;}
table.team {text-align:left;}
table.result {font-family:"Arial Narrow"; font-size:12pt; border:1px AA0055; background:#ddd;}
table td{ margin:O; padding:0 2px; background:#fff;}
h1 {font-size:16pt; font-weight:bold; text-align:left;}
div {max-width: 800px;}
div.blue_rectangle {background: blue; height: 10px; width: 0px;}
div.green_rectangle {background: green; height: 10px; width: 0px;}
</style>
]]


function makeTeamHtml(team, cps)
   local function teamTbl()
      local previos = {
         x = 0,
         y = 0,
      }
      local str = "<tr><td>С</td><td>"..start_time.."</td><td></td><td></td><td></td><td></td><td></td></tr>\n"
      local sum_len = 0
      team.sum = 0
      for i,v in ipairs(team.route) do
         local x,y
         if tonumber(v.id) then
            team.sum = team.sum + v.local_points
            print(v.id)
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
         str = str.."<td>"..string.format("%.2f / %.2f",len,sum_len):gsub('%.',',').."</td>"
         local speed = timeToSec(v.split)/len/60
         str = str..'<td><table width="100%"><tr><td width="40px">'..string.format("%.2f",speed):gsub('%.',',')..
         '</td><td><div class="blue_rectangle" style="width:'..math.floor(speed*3)..
         'px;"></div></td></tr></table></td>'
         if tonumber(v.id) then
            local effectiv = timeToSec(v.split)/v.local_points
            str = str..'<td><table width="100%"><tr><td width="40px">'..
            secToSplit(effectiv)..
            '</td><td><div class="green_rectangle" style="width:'..math.floor(effectiv/10)..
            'px;"></div></td></tr></table></td>'
         else
            str = str.."<td></td>"
         end
         str = str.."</tr>\n"
      end
      str = str .. "<tr><th>&nbsp;</th><th>&nbsp;</th><th>"..team.time..
      "</th><th>"..team.sum.."</th><th>"..string.format("%.2f км",sum_len):gsub('%.',',')..
      "</th><th><strong>"..
      string.format("%.2f",timeToSec(team.time)/sum_len/60):gsub('%.',',').." мин/км</strong></th><th>"..
      secToSplit(timeToSec(team.time)/team.sum).." мин/очко</th></tr>\n"
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

   function makeArrow(c0)
      local x = c0.x / metersInPixel
      local y = c0.y / metersInPixel
      local c = {}
      c[1] = {}
      c[2] = {}
      c[3] = {}
      local a = 50
      local b = 6
      local l = math.sqrt(x^2 + y^2)
      c[1].x = l - a 
      c[2].x = l
      c[3].x = c[1].x
      c[1].y = b
      c[2].y = 0
      c[3].y = -b
      local angle = math.atan(y/x)
      if x < 0 then
         angle = math.pi + angle
      end
      c[1].x,c[1].y = rotate(c[1].x,c[1].y,angle)
      c[2].x,c[2].y = rotate(c[2].x,c[2].y,angle)
      c[3].x,c[3].y = rotate(c[3].x,c[3].y,angle)
      local arrow = 'var arrow = [ '
      for _,i in ipairs{1,2,3,1} do
         arrow = arrow ..'['..math.floor(c[i].x)..','..math.floor(c[i].y)..'],'
      end
      arrow = arrow..' ];'
      return arrow
   end

   local team_html = [[
<html><head><meta http-equiv="Content-Type" content="text/html; charset=utf-8">
]]..style..[[
<title>]]..team.id.."."..team.name.." ("..title..[[, результаты)</title>
</head>
<body>
<h1>]]..title..[[</h1>
<table class="team">
<tr><td>Команда</td><td><b>]]..team.id.."."..team.name..[[</b></td></tr>
<tr><td>Участники</td><td><b>]]..team.second_name..", "..team.first_name..[[</b></td></tr>
<!--<tr><td>Город</td><td>]]..[[</td></tr>-->
<tr><td>Место</td><td>]]..
((tonumber(team.position) < 4) and '<span style="color:#f00; font-weight:bold;">' or '<span>')..
team.position..[[</span> (]]..
team.group..[[)</td></tr>
<tr><td>Очки</td><td>]]..team.sum..[[</td></tr>
<tr><td>Штраф</td><td>]]..(team.sum-team.result)..[[</td></tr>
<tr><td>Время</td><td>]]..team.time..[[</td></tr>
<tr><td>Результат</td><td><b>]]..team.result..[[</b></td></tr>
</table>
<table class="result">
<tr><th>КП</th><th>Время</th><th>Сплит</th><th>Очки</th><th>Расстояние (км)</th><th>Скорость (мин/км)</th><th>Мин/очко</th></tr>
]]..team_tbl..
[[</table><br>
<canvas id="map"></canvas>
<script>
   ]]..cp_list..
   "\n   "..makeArrow(cps[team.route[1].id])..[[

   var canvas = document.getElementById("map");
   var context = canvas.getContext("2d");
   var map = new Image();
   var s = []]..start.x..','..start.y..[[];
   map.src = "]]..mapFileName..[[";
   map.onload = function() {
      canvas.width = this.naturalWidth;
      canvas.height = this.naturalHeight;
      context.scale(]]..javascript_map_scale..","..javascript_map_scale..[[);
      context.drawImage(map, 0, 0);
      context.strokeStyle = "rgba(255,0,0,0.5)";
      context.fillStyle = "rgba(255,0,0,0.5)";
      for (i=0; i<cp_list.length; i++) {
         context.beginPath();
         context.arc(s[0] + cp_list[i][0], s[1] + cp_list[i][1], 3, 0, Math.PI * 2, false);
         context.closePath();
         context.stroke();
         context.fill();
      }
      context.lineWidth = 3;
      var old_x = 0, old_y = 0;
      for (i=0; i<cp_list.length; i++) {
         context.beginPath();
         context.moveTo(s[0] + old_x, s[1] + old_y);
         context.lineTo(s[0] + cp_list[i][0], s[1] + cp_list[i][1]);
         context.stroke();
         old_x = cp_list[i][0];
         old_y = cp_list[i][1];
      }
      context.beginPath();
      context.moveTo(s[0] + arrow[0][0], s[1] + arrow[0][1]);
      for (i=1; i<arrow.length; i++) {
         context.lineTo(s[0] + arrow[i][0], s[1] + arrow[i][1]);
      }
      context.stroke();
      context.fill();
   };
</script>
</body></html>
]]
   local team_file = io.open(outDir.."/team" .. team.id .. ".html","w")
   team_file:write(team_html)
   team_file:close()
end

function makeResultHtml(teams)
   local html = [[
<html><head><meta http-equiv="Content-Type" content="text/html; charset=utf-8">
]]..style..[[
<title>]]..title..[[ Результаты</title>
</head>
<body>
<h1>]]..title..[[ Результаты</h1>
<table class="result">
<tr><th>Абсолют</th><th>Номер</th><th>Название</th><th>Участники</th><th>Результат</th><th>Время</th><th>Место в группе</th></tr>
]]..
(function()
   local str = ""
   for i,v in ipairs(teams) do
      str = str.."<tr>"
      str = str.."<td>"..i.."</td>"
      --str = str.."<td>"..v.subgroup.."</td>"
      str = str.."<td>"..v.id.."</td>"
      str = str..'<td><a href="team'..v.id..'.html">'..v.name..'</a></td>'
      str = str.."<td>"..v.second_name.." "..v.first_name.."</td>"
      str = str.."<td>"..v.result.."</td>"
      str = str.."<td>"..v.time.."</td>"
      str = str.."<td>"..((tonumber(v.position) < 4) and '<span style="color:#f00; font-weight:bold;">' or '<span>')..
      v.position.."</span>("..v.group..")</td>"
      str = str.."</tr>\n"
   end
   return str
end)()
..[[
</table>
</body></html>
]]
   local results_file = io.open(outDir.."/results.html","w")
   results_file:write(html)
   results_file:close()
end

function tableInsertByResult(t,team)
   if not next(t) then
      table.insert(t,team)
      return
   end
   for i,v in ipairs(t) do
      if tonumber(team.result) > tonumber(v.result) then
         table.insert(t,i,team)
         break
      elseif tonumber(team.result) == tonumber(v.result) then
         if timeToSec(team.time) < timeToSec(v.time) then
            table.insert(t,i,team)
            break
         end
      end
      if i == #t then
         table.insert(t,team)
         break
      end
   end
end

local field_name_by_index = {
   "number",
   "id",
   "second_name",
   "first_name",
   "name",
   "subgroup",
   "result",
   "time",
   "position",
   --"_"
}

function parseTeamSplits(team_data, group)
   local team = {}
   team.group = group
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
            cp.id = tonumber(cp.id)
            if cp.id and cp.id ~= 0 then
               _,_,cp.split = string.find(v[1],'(%d+:%d+)$')
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
   end
   
   if not team.result then
      return
   end

   local finish = {}
   finish.id = "Ф"
   local secs = timeToSec(team.time)

   --print("")
   for k,v in pairs(team) do
      --print(k,v)
   end

   local split = secs - prev_secs
   secs = secs + start_secs
   finish.time = secToTime(secs)
   finish.split = secToSplit(split)
   table.insert(team.route,finish)

   return team
end

local teams = {}
function parseSplitsTable(html_data, group)
   for i,v in ipairs(html_data) do
      if (v.xml == "tr" and i ~= 1) then
         local team = parseTeamSplits(v, group)
         if team then
            tableInsertByResult(teams, team)
         end
      end
   end
end

function getGroup(str)
   for i,v in ipairs(groups) do
      if str == v then
         return v
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

local e = xml.find(splits_data,"title")
title = (e and e[1]) or title

for i,v in ipairs(splits_data) do
   if (v.xml == 'h2') then
      local group = getGroup(v[1])
      if group then
         if (splits_data[i+1].xml == "table") then
            parseSplitsTable(splits_data[i+1], group)
         end
      end
   end
end

local cp_data = xml.loadpath(cpFileName)
local checkPoints = {}

for i,v in ipairs(cp_data) do
   print(i,v)
   if v.cp then
      local cp = tonumber(v.cp)
      checkPoints[cp] = {}
      checkPoints[cp].x = v.x * k
      checkPoints[cp].y = v.y * k
   end
end

for i,v in ipairs(teams) do
   makeTeamHtml(v,checkPoints)
end
makeResultHtml(teams)

