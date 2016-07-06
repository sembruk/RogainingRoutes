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
local members = 2
local metersInPixel = 10.3985
local rotateAngle = 19.5 ---< in degrees
local start = {}
start.x = 655 
start.y = 448

---

local xml = require "xml" -- sudo luarocks install xml

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

--[[
local lastLine
for line in io.lines(splitsFileName) do
   if line:find("<h2>"..group.."</h2>") then
   end
   if lastLine and line then
      line = lastLine .. line
   end
   local endChar = string.sub(line,string.len(line))
   if endChar == ';' then
      handleLine(line)
      lastLine = nil
   else
      lastLine = line
   end
end
--]]

local splits_data = xml.loadpath(splitsFileName)
print(xml.find(splits_data, "h2"))

