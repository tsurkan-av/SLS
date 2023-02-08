--[[ Запросы от УДЯ
состояние
запрос	{"request_data": [{"id": "0x00158D0007503021"}], "request_type": "query"}
ответ	[{"type":"light","brightness":100,"state":"ON","color_temp":2891,"id":"0x00158D0007503021"}]

погода
запрос {"request_type":"query","request_data":[{"id":"0xA4C138E143F426BA","custom_data":{"states":["temperature","humidity"],"type":"sensor"}}]}

управление
яркость 
запрос 	{\"request_type\":\"action\",\"request_data\":[{\"id\":\"0x00158D0007503021\",\"capabilities\":[{\"type\":\"devices.capabilities.range\",\"state\":{\"instance\":\"brightness\",\"value\":54}}]}]}
ответ 	[{"type":"light","action_result":{"status":"DONE"},"name":"Ночник","id":"0xA4C138FD68EAA226"}]

color_temp
запрос	{\"request_type\":\"action\",\"request_data\":[{\"id\":\"0x00158D0007503021\",\"capabilities\":[{\"type\":\"devices.capabilities.color_setting\",\"state\":{\"instance\":\"temperature_k\",\"value\":4500}}]}]}
--]]

local fn = (loadfile "/int/func.lib")()

local query = ""
if (Event.Param) then
  query = fn.json_decode(Event.Param, true)
else
  --query = fn.json_decode('{"request_data": [{"id":"0xA4C138FD68EAA226","capabilities":[{"type":"devices.capabilities.color_setting","state":{"instance":"rgb","value":16749000 }},{"type":"devices.capabilities.on_off","state":{"instance":"on","value":false }}]}], "request_type": "action"}')
  query = fn.json_decode('{"request_type":"query","request_data":[{"id":"0xA4C138E143F426BA","custom_data":{"states":["temperature","humidity"],"type":"sensor"}}]}')
end

local out = {}
-- запрос на управление
-- в action походу прилетает только одно действие, так что пох на тип ус-ва. вроде бы
-- пока делаю безусловно. потом всё равно прилетает запрос состояния
-- ответ формирую в YAFn
if (query.request_type == "action") then 
  for _, dev in pairs(query.request_data) do
    local device = dev.id
    -- разбираю умения (capabilities)
    for _, capability in pairs(dev.capabilities) do
      if (capability.state.instance == 'on') then -- вкл/выкл 
        local dstState = ''
        if (capability.state.value) then dstState = 'ON' else dstState = 'OFF' end
        -- отправляю в устройство
        if not (zigbee.set(device, 'state', dstState)) then print('error set on_off to ', device) end
      elseif (capability.state.instance == "rgb") then -- цвет
        -- конвертирую int RGB в xy
        local r,g,b = fn.int_to_rgb(capability.state.value)
        local x, y = fn.rgb_to_cie(r,g,b)
        local color = '{"x":' .. x .. ',"y":' .. y .. '}'
        -- отправляю в устройство
        if not (zigbee.set(device, 'color', color)) then print('error set color to ', device) end
      elseif (capability.state.instance == "temperature_k") then -- цветовая температура
        -- конвертирую Кельвин в Mired
        local temperature_k = math.ceil(1000000 / capability.state.value)
        -- отправляю в устройство
        if not (zigbee.set(device, 'color_temp', temperature_k)) then print('error set color_temp to ', device) end
      elseif (capability.state.instance == "brightness") then -- яркость
        local brightness = capability.state.value
        if (brightness > 5 and brightness <= 100) then brightness = math.ceil(brightness * 2.55) end 
        -- отправляю в устройство
        if not (zigbee.set(device, 'brightness', brightness)) then print('error set brightness to ', device) end
        -- TODO дополнительно включаю если выкл, т.к. может прилететь запрос только на яркость
      end
    end
  end
-- запрос на обновление
elseif (query.request_type == "query") then 
  for _, dev in pairs(query.request_data) do
    local device = dev.id
	
    out[_] = {}
    out[_].id = dev.id
    out[_].properties = {}
    out[_].capabilities = {}
    
    if (dev.custom_data.type == "light") then
      for i = 1, #dev.custom_data.states do
        local state = dev.custom_data.states[i]
        out[_].capabilities[i] = {}
        out[_].capabilities[i].state = {}
        -- вкл/выкл
        if (state == "state") then
          out[_].capabilities[i].type = "devices.capabilities.on_off"
          out[_].capabilities[i].state.instance = "on"
          if (zigbee.value(device, "state") == "ON") then
            out[_].capabilities[i].state.value = true
          else
            out[_].capabilities[i].state.value = false
          end
        elseif (state == "brightness") then  -- яркость
          out[_].capabilities[i].type = "devices.capabilities.range"
          out[_].capabilities[i].state.instance = "brightness"
          -- вернуть надо значение 1-100
          local brightness = zigbee.value(device, state)
            -- расширить в начале диапазона 
          if (brightness > 5 and brightness <= 255) then brightness = math.ceil(brightness / 2.55) end 
          out[_].capabilities[i].state.value = brightness
        elseif (state == "color") then  -- цвет
          out[_].capabilities[i].type = "devices.capabilities.color_setting"
          out[_].capabilities[i].state.instance = "rgb"
            -- конвертирую XY в RGB int 
          local value = fn.json_decode(zigbee.value(device, state))
          local r,g,b = fn.cie_to_rgb(value.x, value.y)
          value = fn.rgb_to_int(r,g,b)
          out[_].capabilities[i].state.value = value
          value = nil
        elseif (state == "color_temp") then -- цветовая температура 
          out[_].capabilities[i].type = "devices.capabilities.color_setting"
          out[_].capabilities[i].state.instance = "temperature_k"
          -- вернуть в кельвинах
          out[_].capabilities[i].state.value = math.ceil(1000000 / zigbee.value(device, "color_temp"))
        end
      end
    elseif (dev.custom_data.type == "sensor") then
      for i = 1, #dev.custom_data.states do
        local state = dev.custom_data.states[i]
        out[_].properties[i] = {}
        out[_].properties[i].type = "devices.properties.float"
        out[_].properties[i].state = {}
        out[_].properties[i].state.instance = state
          if (state == "pressure") then
            out[_].properties[i].state.value = zigbee.value(device, state) * 0.75
          else
            out[_].properties[i].state.value = zigbee.value(device, state)
          end
        end
      end
  end
  print(fn.json_encode(out))
end
