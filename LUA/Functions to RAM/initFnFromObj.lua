local jsonStr = '{"headers":{"request_id":"ПривеТ","authorization":"321"},"request_type":"without_escape","payload":{"devices":[{"id":"0xA4C138FD68EAA226","capabilities":[{"type":"devices.capabilities.color_setting","state":{"instance":"rgb","value":16749000 }},{"type":"devices.capabilities.on_off","state":{"instance":"on","value":false }}]}]}}'
local jsonStrEsc = '{\"headers\":{\"request_id\":\"Пока\",\"authorization\":\"321\"},\"request_type\":\"with_escape\",\"payload\":{\"devices\":[{\"id\":\"0xA4C138FD68EAA226\",\"capabilities\":[{\"type\":\"devices.capabilities.color_setting\",\"state\":{\"instance\":\"rgb\",\"value\":16749000 }},{\"type\":\"devices.capabilities.on_off\",\"state\":{\"instance\":\"on\",\"value\":false }}]}]}}'


local function getFnFromObj(object)
  
  local i = 1
  local result = ''
  local o1, o2 = obj.get('zJson' .. i)
  if o1 then
    repeat
      --print(o1:sub(1,5), o2:sub(1,5))
      result = result .. o1 .. o2
      i = i + 1
      o1, o2 = obj.get('zJson' .. i)
    until not o1
  end
  return result
end

local json = assert(load(getFnFromObj('zJson')))()
print(json.v)

query=json.decode(jsonStr)
query2=json.decode(jsonStrEsc, true)

print(os.time(), query.headers.request_id, "-------------")
print(os.time(), query2.headers.request_id, "-------------")
print(json.encode(query))
print(json.encode(query2,true))
