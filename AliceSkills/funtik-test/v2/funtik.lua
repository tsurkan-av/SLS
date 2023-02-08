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

--print("--------------funtik.lua-------------")
local fn = (loadfile "/int/func.lib")()

local query = ""
if (Event.Param) then
  query = fn.json_decode(Event.Param, true)
else
  --query = fn.json_decode('{"request_data": [{"id":"0xA4C138FD68EAA226","capabilities":[{"type":"devices.capabilities.color_setting","state":{"instance":"rgb","value":16749000 }},{"type":"devices.capabilities.on_off","state":{"instance":"on","value":false }}]}], "request_type": "action"}')
  query = fn.json_decode('{"request_type":"query","request_data":[{"id":"0xA4C138E143F426BA","custom_data":{"states":["temperature","humidity"],"type":"sensor"}}]}')
end

local out = {}
-- local devicesAlice = fn.json_decode(os.fileRead("/int/funtikData.json"), false)

-- запрос на управление
-- в ответ на до формировать state
-- TODO переделать на данные только из запроса

if (query.request_type == "action") then 
  local action_result_ok = {status = "DONE"}
  local action_result_error = {status = "ERROR", error_code = "INVALID_ACTION", error_message = "Что-то пошло не так! См. лог SLS!"}
  for _, dev in pairs(query.request_data) do
    local device = dev.id
    out[_] = {}
    out[_].id = dev.id
    out[_].capabilities = {}
    out[_].properties = {}
    
    -- Лампа
    if (devicesAlice.devices[dev.id].type == "light") then
      -- разбираю умения (capabilities)
      for capabKey, capability in pairs(dev.capabilities) do
	    out[_].capabilities[capabKey] = {}
      out[_].capabilities[capabKey].state = {}
      out[_].capabilities[capabKey].state.action_result = {}
      -- если прилетает color_setting, то разбираю на цвет и/или температуру
      -- смотреть, что прилетает при изменении цвета или color_temp
      -- ЧТО слать в устройство? temperature_k или color???
      if (capability.type:find('color_setting')) then
		    out[_].capabilities[capabKey].type = capability.type
        -- если прилетает rgb, то цвет
        if (capability.state.instance == "rgb") then
		      out[_].capabilities[capabKey].state.instance = "rgb"
            -- конвертирую int RGB в xy
            local r,g,b = fn.int_to_rgb(capability.state.value)
            local x, y = fn.rgb_to_cie(r,g,b)
            local color = '{"x":' .. x .. ',"y":' .. y .. '}'
            -- отправляю в устройство. если true, то пишу в out
            if (zigbee.set(device, 'color', color)) then
              out[_].capabilities[capabKey].state.action_result = action_result_ok
            else
              print('error set color to ', device)
      			  out[_].capabilities[capabKey].state.action_result = action_result_error
            end
          -- если прилетает temperature_k, то цветовая температура
          elseif (capability.state.instance == "temperature_k") then
		        out[_].capabilities[capabKey].state.instance = "temperature_k"
            -- конвертирую Кельвин в Mired
            local temperature_k = math.ceil(1000000 / capability.state.value)
            -- отправляю в устройство. если true, то пишу в out
            if (zigbee.set(device, 'color_temp', temperature_k)) then
              out[_].capabilities[capabKey].state.action_result = action_result_ok
            else
            -- здесь сформировать возврат ошибки - типа device_busy
              print('error set color_temp to ', device)
              out[_].capabilities[capabKey].state.action_result = action_result_error
            end
          end
        elseif (capability.type:find('on_off')) then
          out[_].capabilities[capabKey].type = capability.type
          out[_].capabilities[capabKey].state.instance = "on"
          -- если capability.state.value = true, то включить, иначе выключить
          local dstState = ''
          if (capability.state.value) then dstState = 'ON' else dstState = 'OFF' end
          -- отправляю в устройство. если true, то пишу в out
          if (zigbee.set(device, 'state', dstState)) then
            out[_].capabilities[capabKey].state.action_result = action_result_ok
          else
            print('error set on_off to ', device)
            out[_].capabilities[capabKey].state.action_result = action_result_error
          end
        -- если прилетает range, то в случае с лампой - яркость
        elseif (capability.type:find('range')) then
          out[_].capabilities[capabKey].type = capability.type
          out[_].capabilities[capabKey].state.instance = "brightness"
		      -- если прилетает brightness, то отправлять - 'включено' без включения, т.к. bri включит 
          -- здесь пересчет яркости 100 -> 255 + в начале диапазона не конвертирую для мягкости
          local brightness = capability.state.value
          if (brightness > 5 and brightness <= 100) then brightness = math.ceil(brightness * 2.55) end 
          -- отправляю в устройство. если true, то пишу в out
          if (zigbee.set(device, 'brightness', brightness)) then
            out[_].capabilities[capabKey].state.action_result = action_result_ok
          else
            out[_].capabilities[capabKey].state.action_result = action_result_error
            print('error set brightness to ', device)
          end
        
        end
      end
    elseif (devicesAlice.devices[dev.id].type == "socket") then
      --out[_].type = devicesAlice.devices[dev.id].type
    end
  end
  --print(fn.json_encode(out))
  -- вывод отключил, т.к. безусловно отдаем - всё хорошо)
  
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
--out = json.encode(out)

