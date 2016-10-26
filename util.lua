local upper = {
   ['а'] = 'А',
   ['б'] = 'Б',
   ['в'] = 'В',
   ['г'] = 'Г',
   ['д'] = 'Д',
   ['е'] = 'Е',
   ['ё'] = 'Ё',
   ['ж'] = 'Ж',
   ['з'] = 'З',
   ['и'] = 'И',
   ['й'] = 'Й',
   ['к'] = 'К',
   ['л'] = 'Л',
   ['м'] = 'М',
   ['н'] = 'Н',
   ['о'] = 'О',
   ['п'] = 'П',
   ['р'] = 'Р',
   ['с'] = 'С',
   ['т'] = 'Т',
   ['у'] = 'У',
   ['ф'] = 'Ф',
   ['х'] = 'Х',
   ['ц'] = 'Ц',
   ['ч'] = 'Ч',
   ['ш'] = 'Ш',
   ['щ'] = 'Щ',
   ['ъ'] = 'Ъ',
   ['ы'] = 'Ы',
   ['ь'] = 'Ь',
   ['э'] = 'Э',
   ['ю'] = 'Ю',
   ['я'] = 'Я',
}

local lower = {}
for k,v in pairs(upper) do
   lower[v] = k
end

local _M = {}

function _M.toName(s)
   s = tostring(s)
   local ret = ""
   for i=1,(s and s:len() or 0) do
      local c = s:sub(i,i)
      if i == 1 then
         c = upper[c] or c
      else
         c = lower[c] or c
      end
      ret = ret .. c
   end
   print('>',ret)
   return ret
end

return _M

