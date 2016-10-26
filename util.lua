require "lib.utf8.utf8data"
require "lib.utf8.utf8"
local _M = {}

function _M.toName(s)
   local ret = ''
   for i = 1,(s and s:utf8len() or 0) do
      local c = s:utf8sub(i,i)
      if i == 1 then
         c = string.utf8upper(c) or c
      else
         c = string.utf8lower(c) or c
      end
      ret = ret .. c
   end
   return ret
end

return _M

