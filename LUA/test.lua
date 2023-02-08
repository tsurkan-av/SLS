local jsonStr = '{"headers":{"request_id":"ПривеТ","authorization":"321"},"request_type":"without_escape","payload":{"devices":[{"id":"0xA4C138FD68EAA226","capabilities":[{"type":"devices.capabilities.color_setting","state":{"instance":"rgb","value":16749000 }},{"type":"devices.capabilities.on_off","state":{"instance":"on","value":false }}]}]}}'
local jsonStrEsc = '{\"headers\":{\"request_id\":\"Пока\",\"authorization\":\"321\"},\"request_type\":\"with_escape\",\"payload\":{\"devices\":[{\"id\":\"0xA4C138FD68EAA226\",\"capabilities\":[{\"type\":\"devices.capabilities.color_setting\",\"state\":{\"instance\":\"rgb\",\"value\":16749000 }},{\"type\":\"devices.capabilities.on_off\",\"state\":{\"instance\":\"on\",\"value\":false }}]}]}}'

local fn = (loadfile "fu.lua")()

print(fn.v)

query=fn.json_decode(jsonStr)
query2=fn.json_decode(jsonStrEsc, true)

print(os.time(), query.headers.request_id, "-------------")
print(os.time(), query2.headers.request_id, "-------------")
print(fn.json_encode(query))
print(fn.json_encode(query2,true))



--[[
a={'w',1,2,3,'t'}
o1=''
o2=''
obj.set('f1', o2)
obj.set('f1', o1)
--]]
--o1,o2=obj.get('functions')
--tst=o1 .. o2
--print(tst)
--tst=string.dump(test)
--[[
obj.set('functions', "_")
obj.set('functions', "-")
obj.set('functions', tst)
--]]
--tst,t1,t2=obj.get('functions')
--test=load(os.fileRead('/int/test.lib'))

--test=load(o1 .. o2)

--print(test())
