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

package.path = package.path .. ";./lib/slaxml/?.lua"
local slaxml = require "slaxdom"
local os2 = require("os2")

local config = require "config"

local image = {}
local meters_in_pixel
local start = {}

start.x = config.start_x or 0
start.y = config.start_y or 0

local finish_id = "Ф"

function pairsByKeys(t, f)
   local a = {}
   for k in pairs(t) do
      table.insert(a, k)
   end
   table.sort(a, f)
   local i = 0      -- iterator variable
   local iter = function ()   -- iterator function
      i = i + 1
      if a[i] == nil then
         return nil
      else
         return a[i], t[a[i]]
      end
   end
   return iter
end

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

function floatToString(f)
   return string.format("%.2f", f):gsub('%.',',')
end

local rotateRadians = degToRadian(config.rotateAngle)

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

function getTeamHtmlName(team_index, team_id)
   return "team"..(team_index).."_"..(team_id)..".html"
end

function fixTeamsPositions(teams)
   local counts = {}
   for k,v in pairs(teams) do
      for ii,vv in ipairs(v) do
         if not counts[vv.group] then
            counts[vv.group] = 1
         end
         teams[k][ii].position = counts[vv.group]
         counts[vv.group] = counts[vv.group] + 1
      end
   end
   return teams
end

local style = [[
<style>
body {font-family:"Times New Roman", Times, serif; font-size:14pt;}
table {font-size:12pt; text-align:center;}
table.team {font-size:14pt; text-align:left;}
table.result {border:1px AA0055; background:#ddd;}
table td{ margin:O; padding:0 2px; background:#fff;}
h1 {font-size:18pt; font-weight:bold; text-align:left;}
h2 {font-size:16pt; font-weight:bold; text-align:left;}
div {max-width: 800px;}
div.blue_rectangle {background: blue; height: 10px; width: 0px;}
div.green_rectangle {background: green; height: 10px; width: 0px;}
</style>
]]

function getTeamMemberListForHtml(team)
   local str = ""
   for i,v in ipairs(team) do
      str = str..v.first_name.." "..v.second_name.."<br>"
   end
   return str
end

function makeTeamHtml(index, team, cps)
   local function teamTbl()
      local previos = {
         x = 0,
         y = 0,
      }
      local str = "<tr><td>С</td><td>"..team.start_time.."</td><td></td><td></td><td></td><td></td><td></td><td></td></tr>\n"
      local sum_len = 0
      team.sum = 0
      print(string.format("Make HTML for team No %s",team.id))
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
         str = str.."<td>"..(v.time or '-').."</td>"
         str = str.."<td>"..(v.split or '-').."</td>"
         if tonumber(v.id) then
            str = str.."<td>"..v.local_points.." / "..team.sum.."</td>"
         else
            str = str.."<td></td>"
         end
         --print(v.id, v.split)
         str = str.."<td>"..floatToString(len).." / "..floatToString(sum_len).."</td>"
         if v.split then
            local speed = len/timeToSec(v.split)*3600
            str = str.."<td>"..floatToString(speed).."</td>"
            local pace = timeToSec(v.split)/len/60
            str = str..'<td><table width="100%"><tr><td width="40px">'..floatToString(pace)..
                  '</td><td><div class="blue_rectangle" style="width:'..math.floor(pace*3)..
                  'px;"></div></td></tr></table></td>'
         else
            str = str..'<td>-</td><td>-</td>'
         end
         if tonumber(v.id) and v.split then
            local effectiv = timeToSec(v.split)/v.local_points
            str = str..'<td><table width="100%"><tr><td width="40px">'..
            secToSplit(effectiv)..
            '</td><td><div class="green_rectangle" style="width:'..math.floor(effectiv/10)..
            'px;"></div></td></tr></table></td>'
         else
            str = str.."<td>-</td>"
         end
         str = str.."</tr>\n"
      end
      str = str .. "<tr><th>&nbsp;</th><th>&nbsp;</th><th>"..team.time..
      "</th><th>"..team.sum.."</th><th>"..floatToString(sum_len)..
      " км </th><th><strong>"..
      floatToString(sum_len/timeToSec(team.time)*3600).." км/ч</strong></th><th><strong>"..
      floatToString(timeToSec(team.time)/sum_len/60).." мин/км</strong></th><th>"..
      secToSplit(timeToSec(team.time)/team.sum).." мин/очко</th></tr>\n"
      local sum_len = sum_len + math.sqrt((0 - previos.x)^2 + (0 - previos.y)^2)
      return str
   end

   local team_tbl = teamTbl()

   local cp_list = 'var cp_list = [ '
   for i,v in ipairs(team.route) do
      if tonumber(v.id) then
         local x_p = math.floor(cps[v.id].x / meters_in_pixel)
         local y_p = math.floor(cps[v.id].y / meters_in_pixel)
         cp_list = cp_list ..'['..x_p..','..y_p..'],'
      end
   end
   cp_list = cp_list..'[0,0] ];'

   function makeArrow(c0)
      if not c0 then
         return ""
      end
      local x = c0.x / meters_in_pixel
      local y = c0.y / meters_in_pixel
      local c = {}
      c[1] = {}
      c[2] = {}
      c[3] = {}
      local a = 20
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
<html><head><meta http-equiv="Content-Type" content="text/html" charset="windows-1251">
]]..style..[[
<title>]]..team.id..". "..team.name --[[(team[1].first_name.." "..team[1].second_name))]]..
" ("..config.title..[[, результаты)</title>
</head>
<body>
<h1>]]..config.title..[[</h1>
<table class="team">
<tr><td>Команда</td><td><b>]]..team.id..(config.display_team_name and (". "..team.name) or (""))..[[</b></td></tr>
<tr><td>Участники</td><td><b>]]..getTeamMemberListForHtml(team) --[[team[1].first_name.." "..team[1].second_name]]..[[</b></td></tr>
<!--<tr><td>Город</td><td>]]..(team.city or '')..[[</td></tr>-->
<tr><td>Место</td><td>]]..
((tonumber(team.position) < 4) and '<span style="color:#f00; font-weight:bold;">' or '<span>')..
team.position..[[</span> (]]..
team.group..[[)</td></tr>
<tr><td>Очки</td><td>]]..team.sum..[[</td></tr>
<tr><td>Штраф</td><td>]]..(team.sum > tonumber(team.result) and team.sum-team.result or 0)..[[</td></tr>
<tr><td>Время</td><td>]]..team.time..[[</td></tr>
<tr><td>Результат</td><td><b>]]..team.result..[[</b></td></tr>
</table>
<table class="result">
<tr><th>КП</th><th>Время</th><th>Сплит</th><th>Очки</th><th>Расстояние, км</th><th>Скорость, км/ч</th><th>Темп, мин/км</th><th>Мин/очко</th></tr>
]]..team_tbl..
[[</table><br>
<canvas id="map"></canvas>
<script>
   ]]..cp_list..
   "\n   "..(team.route[1] and makeArrow(cps[team.route[1].id]) or '')..[[

   var canvas = document.getElementById("map");
   var context = canvas.getContext("2d");
   var map = new Image();
   var s = []]..start.x..','..start.y..[[];
   map.src = "map.jpg";
   map.onload = function() {
      canvas.width = this.naturalWidth;
      canvas.height = this.naturalHeight;
      context.scale(]]..config.javascript_map_scale..","..config.javascript_map_scale..[[);
      context.drawImage(map, 0, 0);
      context.strokeStyle = "rgba(255,0,0,0.6)";
      context.fillStyle = "rgba(255,0,0,0.6)";
      for (i=0; i<cp_list.length; i++) {
         context.beginPath();
         context.arc(s[0] + cp_list[i][0], s[1] + cp_list[i][1], 3, 0, Math.PI * 2, false);
         context.closePath();
         context.stroke();
         context.fill();
      }
      context.lineWidth = 4;
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
   local team_file = assert(io.open(config.out_dir.."/"..getTeamHtmlName(index,team.id),"w"))
   team_file:write(team_html)
   team_file:close()
end

function makeClassResultTable(class_name, class)
   return [[
<h2>]]..class_name..[[</h2>
<table class="result">
<tr><th>Абсолют</th><th>Номер</th>]]..
(config.display_team_name and "<th>Название</th>" or "")..
[[<th>Участники</th><th>Результат</th><th>Время</th><th>Место в группе</th></tr>
]]..
(function()
   local str = ""
   for i,v in ipairs(class) do
      str = str.."<tr>"
      str = str.."<td>"..i.."</td>"
      --str = str.."<td>"..v.subgroup.."</td>"
      str = str.."<td>"..v.id.."</td>"
      if config.display_team_name then
         str = str..'<td><a href="'..getTeamHtmlName(i,v.id)..'">'..v.name..'</a></td>'
         str = str.."<td>"..getTeamMemberListForHtml(v).."</td>"
      else
         str = str..'<td><a href="'..getTeamHtmlName(i,v.id)..'">'..getTeamMemberListForHtml(v)..'</a></td>'
      end
      str = str.."<td>"..v.result.."</td>"
      str = str.."<td>"..v.time.."</td>"
      str = str.."<td>"..((tonumber(v.position) < 4) and '<span style="color:#f00; font-weight:bold;">' or '<span>')..
      v.position.."</span>("..v.group..")</td>"
      --str = str.."<td>"..v.subgroup.."</td>"
      str = str.."</tr>\n"
   end
   return str
end)()
..[[
</table>
]]
end

function makeResultHtml(teams)
   print("Make result HTML")
   local html = [[
<html><head><meta http-equiv="Content-Type" content="text/html" charset="windows-1251">
]]..style..[[
<title>]]..config.title..[[. Результаты</title>
</head>
<body>
<h1>]]..config.title..[[. Результаты</h1>]]..
(function()
   local str = ""
   for k,v in pairsByKeys(teams) do
      str = makeClassResultTable(k,v)..str
   end
   return str
end) ()
..[[
</body></html>
]]
   local results_file = io.open(config.out_dir.."/results.html","w")
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

function parseMemberSplits(member_data, start_time)
   local member = {}
   member.route = {}
   local member_secs = 0
   for i,v in ipairs(member_data.el) do
      if (v.name == "td") then
         local text = v.kids[1] and v.kids[1].value
         text = text or ""
         if config.sfr_split_field_name_by_index[i] then
            member[config.sfr_split_field_name_by_index[i]] = text
            if config.sfr_split_field_name_by_index[i] == "id" then
               print(string.format("Parse splits of member No %s...", member.id))
               _,_,member.team_id = string.find(member.id,"^(%d+)%.-")
            end
         else
            local cp = {}
            _,_,cp.time,cp.id = string.find(text,'^(%d+:%d+)%[(%d+)%]')
            cp.id = tonumber(cp.id)
            local in_ignore = false
            if config.ignore_list then
               for k,v in pairs(config.ignore_list) do
                  if cp.id == v then
                     in_ignore = true
                     break
                  end
               end
            end
            if cp.id and cp.id ~= 0 and not in_ignore then
               _,_,cp.split = string.find(text,'(%d+:%d+)$')
               if cp.split == nil then
                  cp.split = cp.time
               end

               member_secs = member_secs + timeToSec(cp.split)

               cp.secs = member_secs
               cp.time = secToTime(member_secs + timeToSec(start_time))
               _,_,cp.local_points = string.find(cp.id,'^(%d+)%d$')
               table.insert(member.route,cp)
            end
         end
      end
   end
   
   if not member.result or member.result == '' or #member.route < 1 then
      return
   end

   local finish = {}
   finish.id = finish_id
   local secs = timeToSec(member.time)

   local split
   -- FIXME
   for i = 0,100 do
      split = secs - member.route[#member.route-i].secs
      if split > 0 then
         break
      end
   end
   secs = secs + timeToSec(start_time)
   finish.time = secToTime(secs)
   finish.split = secToSplit(split)
   -- FIXME Finish split
   table.insert(member.route,finish)

   print("done")
   return member
end

function makeTableForRating(teams)
   local t = {}
   for class_name, class in pairs(teams) do
      for _,team in ipairs(class) do
         for i,v in ipairs(team) do
            table.insert(t,string.format("%s %s\t%d\t%d\t%d",
                                         v.second_name,
                                         v.first_name,
                                         v.year_of_birth,
                                         #team,
                                         v.result))
         end
      end
   end
   local f = io.open("out/for_rating.tsv",'w')
   f:write(table.concat(t,'\n'))
   f:close()
end

local teams = {}
function parseSfrSplitsTable(html_data, group, class, start)
   print("Class: ",class)
   print("Group: ",group)
   local teams_unsort = {}
   for i,v in ipairs(html_data.el) do
      if (v.name == "tr" and i ~= 1) then
         local member = parseMemberSplits(v,start)
         if member then
            --print(member.id,member.team_id)
            if teams_unsort[member.team_id] == nil then
               teams_unsort[member.team_id] = {}
            end
            table.insert(teams_unsort[member.team_id],member)
         end
      end
   end
   for k,v in pairs(teams_unsort) do
      v.id = tonumber(v[1].team_id)
      v.result = v[#v].result
      v.time   = v[#v].time
      v.route  = v[#v].route
      --v.position = v[1].position
      v.city = v[1].city

      v.group = group
      v.start_time = start

      local names = {}
      v.name = nil
      for ii,vv in ipairs(v) do
         if not names[vv.name] then
            names[vv.name] = true
            v.name = v.name and (v.name..' - '..vv.name) or vv.name
         end
      end

      if not config.display_team_name or v.name == nil or v.name == "" then
         v.name = ""
         if #v == 1 then
            v.name = v[1].first_name.." "..v[1].second_name
         else
            for ii,vv in ipairs(v) do
               v.name = v.name.." "..vv.second_name
            end
         end
      end

      if teams[class] == nil then
         teams[class] = {}
      end

      tableInsertByResult(teams[class], v)
   end
   return teams
end

function getGroup(str)
   for class_name,class in pairs(config.groups) do
      for _,group in ipairs(class) do
         if str == group then
            return group, class_name, class.start
         end
      end
   end
end

function xml_find(xml_data, name)
   for _,v in pairs(xml_data.el or xml_data.kids) do
      if v.type == "element" and v.name == name then
         return v
      end
   end
   return nil
end

function parseSfrSplitsHtml(splits_filename)
   local file = io.open(splits_filename)
   local docstr = file:read("*a")
   file:close()

   docstr = docstr:gsub("<meta.->","")
   docstr = docstr:gsub("<style>.-</style>","")
   docstr = docstr:gsub("<head>.-</head>","")
   docstr = docstr:gsub("<nobr>","")
   docstr = docstr:gsub("</nobr>","")
   docstr = docstr:gsub("<br>","")
   docstr = docstr:gsub("<html>","")
   docstr = docstr:gsub("</html>","")
   docstr = docstr:gsub("<body>","")
   docstr = docstr:gsub("</body>","")
   docstr = docstr:gsub("<tbody.->","")
   docstr = docstr:gsub("</tbody>","")
   docstr = "<document>"..docstr.."</document>"

   local splits_data = slaxml:dom(docstr)
   splits_data = splits_data.root

   local e = xml_find(splits_data,"h1")
   e = e.kids[1]
   local text = e.type == "text" and e.value
   config.title = config.title or text:gsub("%s+Протокол.+$","")
   config.title = config.title:gsub("%.$","")

   for i,v in ipairs(splits_data.el) do
      if (v.name == 'h2') then
         local group,class_name,start = getGroup(v.kids[1].value)
         if group then
            if (splits_data.el[i+1].name == "table") then
               parseSfrSplitsTable(splits_data.el[i+1], group, class_name, start)
            end
         end
      end
   end
end

function parseBrokenCps(filename)
   local broken_cps_tbl = {}
   if not filename then
      return
   end
   local f = io.open(filename)
   if not f then
      return
   end
   for line in f:lines() do
      local _,_,team_id,broken_cp,after = string.find(line,"^(%d+)%.-%d-,%s-(%d+),%s-(%w+)$")
      --print('>',line)
      --print('>',team_id,broken_cp, after)
      team_id = tonumber(team_id)
      broken_cp = tonumber(broken_cp)
      after = tonumber(after)
      --FIXME
      if after == 240 then
         after = finish_id
      end
      if team_id then
         if not broken_cps_tbl[team_id] then
            broken_cps_tbl[team_id] = {}
         end
         table.insert(broken_cps_tbl[team_id],{cp_id = broken_cp, after = after}) 
      end
   end
   f:close()
   return broken_cps_tbl
end

function fixSplits(team, broken_cps)
   if type(broken_cps) ~= "table" then
      return team
   end
   for _,v in ipairs(broken_cps) do
      for i,vv in ipairs(team.route) do
         if vv.id == v.cp_id then
            table.remove(team.route,i)
         end
      end
      for i,vv in ipairs(team.route) do
         if vv.id == v.after then
            local cp = {}
            cp.id = v.cp_id
            _,_,cp.local_points = string.find(cp.id,'^(%d+)%d$')
            table.insert(team.route, i, cp)
            break
         end
      end
   end
   return team
end

function isIofCourseDataXmlFile(course_data_filename)
   --[[
   local data = pcall(xml.loadpath,course_data_filename)
   if data and data.xml == "CourseData" and xml.find(data,"IOFVersion") then
      return true
   end
   --]]
   local data = slaxml:dom(io.open(course_data_filename):read("*all"))
   if data and data.root then
      return true
   end

   return false
end

function parseIofCourseDataXml(course_data_filename)
   local cp_data = slaxml:dom(io.open(course_data_filename):read("*all"))
   local cps = {}
   local start_position = {}
   local map_position = {}
   local scale_factor
   do
      local e =  assert(xml_find(cp_data,"Map"))
      scale_factor = tonumber(assert(xml_find(e,"Scale"))[1])
      meters_in_pixel = scale_factor * 0.0254 / config.map_dpi
      local position = assert(xml_find(e,"MapPosition"))
      map_position.x = assert(tonumber(position.x))
      map_position.y = assert(tonumber(position.y))
   end
   do
      local e = assert(xml_find(cp_data,"StartPoint"))
      local position = assert(xml_find(e,"MapPosition"))
      start_position.x = assert(tonumber(position.x))
      start_position.y = assert(tonumber(position.y))
      start.x = math.floor((map_position.x + start_position.x) * scale_factor / 1000 / meters_in_pixel)
      start.y = math.floor((map_position.y - start_position.y) * scale_factor / 1000 / meters_in_pixel)
   end
   for i,v in ipairs(cp_data) do
      if v.xml == "IOFVersion" then
         assert(v.version == "2.0.3","Unsupported IOF Course Data version")
      elseif v.xml == "Control" then
         local code = assert(tonumber(xml_find(v,"ControlCode")[1]))
         cps[code] = {}
         local position = assert(xml_find(v,"MapPosition"))
         cps[code].x = (assert(tonumber(position.x)) - start_position.x) * scale_factor / 1000
         cps[code].y = -(assert(tonumber(position.y)) - start_position.y) * scale_factor / 1000
      end
   end
   return cps
end

function parseCourseDataTxt(course_data_filename)
   local cps = {}
   start.x = start.x or 0
   start.y = start.y or 0
   meters_in_pixel = config.map_scale_factor * 0.0254 / config.map_dpi
   for line in io.lines(course_data_filename) do
      local _,_,code,x,y = string.find(line,"^(%d+)%s+([%d%-]+)%s+([%d%-]+)$")
      if not code then
         _,_,code,x,y = string.find(line,"^(%d+),([%d%-]+),([%d%-]+)$")
      end
      code = tonumber(code)
      if code then
         x = tonumber(x)
         y = -tonumber(y)
         cps[code] = {}
         x, y = rotate(x, y, rotateRadians)
         cps[code].x = x
         cps[code].y = y
      end
   end

   return cps
end

function parseCourseDataFile(course_data_filename)
   if isIofCourseDataXmlFile(course_data_filename) then
      print("Not implemented for new XML parser!")
      return nil
      --return parseIofCourseDataXml(course_data_filename)
   end
   return parseCourseDataTxt(course_data_filename)
end

os2.rm(config.out_dir)
os2.mkdir(config.out_dir)
os2.copy(config.map_filename, config.out_dir.."/map.jpg")
os2.copy(config.splits_filename, config.out_dir.."/splits.htm")
os2.copy(config.course_data_filename, config.out_dir.."/coords.txt")

local broken_cps_tbl = parseBrokenCps(config.broken_cps)
parseSfrSplitsHtml(config.splits_filename)

local check_points = parseCourseDataFile(config.course_data_filename)

teams = fixTeamsPositions(teams)

makeTableForRating(teams)

for _,class in pairs(teams) do
   for i,v in ipairs(class) do
      if broken_cps_tbl then
         v = fixSplits(v, broken_cps_tbl[v.id])
      end
      makeTeamHtml(i,v,check_points)
   end
end
makeResultHtml(teams)

