--[[ Запросы от УДЯ
состояние
запрос	{"request_data": [{"id": "0x00158D0007503021"}], "request_type": "query"}
ответ	[{"type":"light","brightness":100,"state":"ON","color_temp":2891,"id":"0x00158D0007503021"}]
яркость 
запрос 	{\"request_type\":\"action\",\"request_data\":[{\"id\":\"0x00158D0007503021\",\"capabilities\":[{\"type\":\"devices.capabilities.range\",\"state\":{\"instance\":\"brightness\",\"value\":54}}]}]}
ответ 	[{"type":"light","action_result":{"status":"DONE"},"name":"Ночник","id":"0xA4C138FD68EAA226"}]



--]]

--print("--------------funtik.lua-------------")
--local fn = (loadfile "/int/func.lib")()
local fn = (loadfile "fu.lua")()
local color_temp_ratio = 1000000 -- приводим значение устройства mired 153-500 к Кельвинам 2700-9000
local percent100_ratio = 2.55 -- приводим значение устройства 1-255 к процентам 1-100
-- print(Event.Param)

local query = ""
--[[
if (Event.Param) then
  query = fn.json_decode(Event.Param, true)
else
--]]
  query = fn.json_decode('{"request_data": [{"id":"0xA4C138FD68EAA226","capabilities":[{"type":"devices.capabilities.color_setting","state":{"instance":"rgb","value":16749000 }},{"type":"devices.capabilities.on_off","state":{"instance":"on","value":false }}]}], "request_type": "action"}')
  --query = fn.json_decode('{"request_data": [{"id": "0x00158D0007503021"}], "request_type": "query"}')
--end

local out = {}
--local devicesAlice = fn.json_decode(os.fileRead("/int/funtikData.json"), false)
local devicesAlice = fn.json_decode('{"common": {"color_temp_ratio": 18, "percent100_ratio": 2.55}, "devices": {"0x00158D0007503021": {"color_setting": {"temperature_k": {"max": 6500, "min": 2700, "precision": 1}}, "friendly_name": "lmp_bedroom", "ieeeAddr": "0x00158D0007503021", "name": "Люстра", "room": "Спальня", "type": "light"}, "0xA4C138FD68EAA226": {"color_setting": {"color_model": "rgb", "temperature_k": {"max": 6500, "min": 2700, "precision": 1}}, "friendly_name": "lmp_bedroom-nightlight-papa", "ieeeAddr": "0xA4C138FD68EAA226", "name": "Ночник", "room": "Спальня", "type": "light"}}, "objects": {"name": "Люди", "type": "personesTracker"}}')
-- запрос на управление
-- в ответ на до формировать state
if (query.request_type == "action") then 
  for _, dev in pairs(query.request_data) do
    local device = dev.id
    out[_] = {}
    out[_].id = dev.id
	
    
    -- Лампа
    if (devicesAlice.devices[dev.id].type == "light") then
	  -- тип и name не нужны 
      --out[_].type = devicesAlice.devices[dev.id].type
      --out[_].name = devicesAlice.devices[dev.id].name
	  
	  
      -- разбираю умения (capabilities)
      for capabKey, capability in pairs(dev.capabilities) do
	  print(capabKey)
		out[_].capabilities = {}
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
            --[[
            local r,g,b = fn.int_to_rgb(capability.state.value)
            local x, y = fn.rgb_to_cie(r,g,b)
            local color = '{"x":' .. x .. ',"y":' .. y .. '}'
            -- отправляю в устройство. если true, то пишу в out
            if (zigbee.set(device, 'color', color)) then
              out[_].capabilities[capabKey].state.action_result.status = "DONE"
            else
              print('error set color to ', device)
              --]]
			  out[_].capabilities[capabKey].state.action_result.status = "ERROR"
			  out[_].capabilities[capabKey].state.action_result.error_code = "INVALID_ACTION"
			  out[_].capabilities[capabKey].state.action_result.error_message = "Что-то пошло не так! См. лог SLS!"
            --end
          -- если прилетает temperature_k, то цветовая температура
          elseif (capability.state.instance == "temperature_k") then
            -- конвертирую Кельвин в Mired
            local temperature_k = math.ceil(color_temp_ratio / capability.state.value)
            -- отправляю в устройство. если true, то пишу в out
            if (zigbee.set(device, 'color_temp', temperature_k)) then
			  out[_].capabilities[capabKey].state.action_result.status = "DONE"
            else
            -- здесь сформировать возврат ошибки - типа device_busy
              print('error set color_temp to ', device)
			  out[_].capabilities[capabKey].state.action_result.status = "ERROR"
			  out[_].capabilities[capabKey].state.action_result.error_code = "INVALID_ACTION"
			  out[_].capabilities[capabKey].state.action_result.error_message = "Что-то пошло не так! См. лог SLS!"
            end
          end
        elseif (capability.type:find('on_off')) then
          -- если capability.state.value = true, то включить, иначе выключить
          local dstState = ''
          if (capability.state.value) then dstState = 'ON' else dstState = 'OFF' end
          -- отправляю в устройство. если true, то пишу в out
          if (zigbee.set(device, 'state', dstState)) then
            out[_].capabilities[capabKey].state.action_result.status = "DONE"
          else
            out[_].capabilities[capabKey].state.action_result.status = "ERROR"
			out[_].capabilities[capabKey].state.action_result.error_code = "INVALID_ACTION"
			out[_].capabilities[capabKey].state.action_result.error_message = "Что-то пошло не так! См. лог SLS!"
            print('error set on_off to ', device)
          end
		-- если прилетает range, то в случае с лампой - яркость
		elseif (capability.type:find('range')) then
          -- если прилетает brightness, то отправлять - 'включено' без включения, т.к. bri включит 
          -- здесь пересчет яркости 100 -> 255 + в начале диапазона не конвертирую для мягкости
          local brightness = capability.state.value
          if (brightness > 5 and brightness <= 100) then brightness = math.ceil(brightness * percent100_ratio) end 
          -- отправляю в устройство. если true, то пишу в out
          if (zigbee.set(device, 'brightness', brightness)) then
            out[_].capabilities[capabKey].state.action_result.status = "DONE"
          else
            out[_].capabilities[capabKey].state.action_result.status = "ERROR"
			out[_].capabilities[capabKey].state.action_result.error_code = "INVALID_ACTION"
			out[_].capabilities[capabKey].state.action_result.error_message = "Что-то пошло не так! См. лог SLS!"
            print('error set brightness to ', device)
          end
        
        end
      end
    elseif (devicesAlice.devices[dev.id].type == "socket") then
      --out[_].type = devicesAlice.devices[dev.id].type
    end
  end
-- запрос на обновление
elseif (query.request_type == "query") then 
  for _, dev in pairs(query.request_data) do
    local device = dev.id
	
    out[_] = {}
    out[_].id = dev.id
    
    if (devicesAlice.devices[dev.id].type == "light") then
      out[_].type = devicesAlice.devices[dev.id].type
      out[_].state = zigbee.value(device, "state")
      -- вернуть надо значение 1-100
      local brightness = zigbee.value(device, "brightness")
        -- расширить в начале диапазона 
      if (brightness > 5 and brightness <= 255) then brightness = math.ceil(brightness / percent100_ratio) end 
      out[_].brightness = brightness
        -- вернуть в кельвинах
      out[_].color_temp = math.ceil(color_temp_ratio / zigbee.value(device, "color_temp"))
      -- если есть color_model, добавлю инфу о цвете
      if (devicesAlice.devices[dev.id].color_setting.color_model) then
        -- конвертирую XY в RGB int 
        local color = fn.json_decode(zigbee.value(device, "color"))
        local r,g,b = fn.cie_to_rgb(color.x, color.y)
        color = fn.rgb_to_int(r,g,b)
        out[_].color = color
      end
    elseif (devicesAlice.devices[dev.id].type == "socket") then
      out[_].type = devicesAlice.devices[dev.id].type
    end
  end

end
--out = json.encode(out)
print(fn.json_encode(out))
