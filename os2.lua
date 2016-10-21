local _M = {}

local function inLinux()
   if pcall(function() io.popen("uname"):read('*all') end) then
      return true
   end
end

function selectByOs(winVariant, unixVariant)
   if(inLinux()) then
      return unixVariant
   end
   print('> win variant')
   return winVariant
end

local pwd   = selectByOs("cd ",         "pwd ")
local rm    = selectByOs("rmdir /S /Q ","rm -rf ")
local mkdir = selectByOs("mkdir ",      "mkdir -p ")
local ls    = selectByOs("dir /B /S ",  "find ")
local cp    = selectByOs("copy ",       "cp -rf ")
local mv    = selectByOs("move /Y ",    "mv -f ")
local null  = selectByOs("nul",         "/dev/null")
local slash = selectByOs( "\\",         "/")

local function convertpath(path)
   return string.gsub(path,"/",slash)
end

function _M.rm(path)
   if path then
      print(string.format("Remove '%s'",path))
      os.execute(rm .. convertpath(path).." > ".. null)
   end
end

function _M.mkdir(dir)
   print(string.format("Make dir '%s'",dir))
   os.execute(mkdir .. convertpath(dir).." > ".. null)
end

function _M.copy(from,to)
   print(string.format("Copy from '%s' to '%s'", from, to))
   os.execute(cp .. convertpath(string.format("%s %s ",from,to)).." > ".. null)
end

function _M.move(from,to)
   os.execute(mv .. convertpath(string.format("%s %s ",from,to)).." > ".. null)
end

return _M

