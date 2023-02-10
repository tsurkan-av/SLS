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

local out = {}
local query = ""
local capability_cnt = 0
local property_cnt = 0
local fn = (loadfile "/int/func.lib")()
local ststesMapSLS2YA = {
  -- on_off map
  ON = true,
  OFF = false,
  AUTO = false,
  state = {instance = "on", type = "devices.capabilities.on_off"},
  color = {instance = "rgb", type = "devices.capabilities.color_setting"},
  color_temp = {instance = "temperature_k", type = "devices.capabilities.color_setting"},
  brightness = {instance = "brightness", type = "devices.capabilities.range"},
  backlight_mode = {instance = "backlight", type = "devices.capabilities.toggle"},
  power_on_behavior = {instance = "controls_locked", type = "devices.capabilities.toggle"},
  power = {instance = "power", type = "devices.properties.float"},
  current = {instance = "amperage", type = "devices.properties.float"},
  voltage = {instance = "voltage", type = "devices.properties.float"},
  humidity = {instance = "humidity", type = "devices.properties.float"},
  pressure = {instance = "pressure", type = "devices.properties.float"},
  temperature = {instance = "temperature", type = "devices.properties.float"},
  battery = {instance = "battery_level", type = "devices.properties.float"},
  -- SLS
  led_bri = {instance = "brightness", type = "devices.capabilities.range"},
  led_color = {instance = "rgb", type = "devices.capabilities.color_setting"},
  led_effect = {instance = "channel", type = "devices.capabilities.range"},
  led_state = {instance = "on", type = "devices.capabilities.on_off"}
}
local function update(capabilty, state, device, cnt)
  if (capabilty) then 
    capability_cnt = capability_cnt + 1
    out[cnt].capabilities[capability_cnt] = {}
    out[cnt].capabilities[capability_cnt].type = ststesMapSLS2YA[state].type
    out[cnt].capabilities[capability_cnt].state = {}
    out[cnt].capabilities[capability_cnt].state.instance = ststesMapSLS2YA[state].instance
  else
    property_cnt = property_cnt + 1
    out[cnt].properties[property_cnt] = {}
    out[cnt].properties[property_cnt].type = ststesMapSLS2YA[state].type
    out[cnt].properties[property_cnt].state = {}
    out[cnt].properties[property_cnt].state.instance = ststesMapSLS2YA[state].instance
  end
  if (device == "SLS_Led") then
    return obj.get(device)
  else
    return zigbee.value(device, state)
  end
end

if (Event.Param) then
  query = fn.json_decode(Event.Param, true)
else
  --query = fn.json_decode('{"request_data": [{"id":"0xA4C138FD68EAA226","capabilities":[{"type":"devices.capabilities.color_setting","state":{"instance":"rgb","value":16749000 }},{"type":"devices.capabilities.on_off","state":{"instance":"on","value":false }}]}], "request_type": "action"}')
  --query = fn.json_decode('{"request_type":"query","request_data":[{"id":"0xA4C138FD68EAA226","custom_data":{"states": ["state", "brightness", "color_temp", "color"],"type":"socket"}}]}')
  query = fn.json_decode('{"request_type":"query","request_data":[{"id":"SLS_Led","custom_data":{"states": ["led_state", "led_bri", "led_effect", "led_color"],"type":"socket"}}]}')
  --query = fn.json_decode('{"request_type":"query","request_data":[{"id":"0xA4C138AAA29895A8","custom_data":{"states": ["state", "current", "voltage", "power", "backlight_mode", "power_on_behavior"],"type":"socket"}}]}')
end

-- запрос на управление
-- в action походу прилетает только одно действие, так что пох на тип ус-ва. вроде бы
-- пока делаю безусловно. потом всё равно прилетает запрос состояния
-- ответ формирую в YAFn
if (query.request_type == "action") then 
  for dev_key, dev in pairs(query.request_data) do
    local device = dev.id
    local dstState = ''
    -- разбираю умения (capabilities)
    for capability_key, capability in pairs(dev.capabilities) do
      if (capability.state.instance == 'on') then -- вкл/выкл 
        if (device == "SLS") then
        -- TODO управление led SLS

        else
          if (capability.state.value) then dstState = 'ON' else dstState = 'OFF' end
          -- отправляю в устройство
          if not (zigbee.set(device, 'state', dstState)) then print('error set on_off to ', device) end
        end
      elseif (capability.state.instance == 'backlight') then -- вкл/выкл подсветки
        if (capability.state.value) then dstState = 'ON' else dstState = 'OFF' end
        -- отправляю в устройство
        if not (zigbee.set(device, 'backlight_mode', dstState)) then print('error set on_off to ', device) end
      elseif (capability.state.instance == 'controls_locked') then -- вкл/выкл поведения при откл питания розетки
        if (capability.state.value) then dstState = 'ON' else dstState = 'OFF' end
        -- отправляю в устройство
        if not (zigbee.set(device, 'power_on_behavior', dstState)) then print('error set on_off to ', device) end
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
        -- дополнительно включать не требуется
      end
    end
  end
-- запрос на обновление
elseif (query.request_type == "query") then 
  for dev_key, dev in pairs(query.request_data) do
    local device = dev.id
    capability_cnt = 0
    property_cnt = 0

    out[dev_key] = {}
    out[dev_key].id = dev.id
    out[dev_key].properties = {}
    out[dev_key].capabilities = {}
      
    for i = 1, #dev.custom_data.states do
      local state = dev.custom_data.states[i]
      -- умения
      if (state == "state") -- вкл/выкл 
        or (state == "backlight_mode") -- вкл/выкл подсветки кнопки
        or (state == "power_on_behavior") -- вкл/выкл поведения при откл питания розетки
        then 
          local value = ststesMapSLS2YA[update(true, state, device, dev_key)]
          out[dev_key].capabilities[capability_cnt].state.value = value
      elseif (state == "brightness") then -- яркость - расширить в начале диапазона 
        local value = update(true, state, device, dev_key)
        if (value > 5 and value <= 255) then value = math.ceil(value / 2.55) end 
        out[dev_key].capabilities[capability_cnt].state.value = value
      elseif (state == "color") then -- цвет - конвертирую XY в RGB int 
        local value = fn.json_decode(update(true, state, device, dev_key))
        local r,g,b = fn.cie_to_rgb(value.x, value.y)
        value = fn.rgb_to_int(r,g,b)
        out[dev_key].capabilities[capability_cnt].state.value = value
      elseif (state == "color_temp") then -- яркость - вернуть в кельвинах
        local value = update(true, state, device, dev_key)
        out[dev_key].capabilities[capability_cnt].state.value = math.ceil(1000000 / value)
      elseif (state == "led_state") then -- вкл/выкл SLS Led
        local value = fn.json_decode(update(true, state, device, dev_key))
        out[dev_key].capabilities[capability_cnt].state.value = ststesMapSLS2YA[value.mode]
      elseif (state == "led_bri") then -- яркость SLS Led
        local value = fn.json_decode(update(true, state, device, dev_key))
        if (value.brightness > 5 and value.brightness <= 255) then value = math.ceil(value.brightness / 2.55) end 
        out[dev_key].capabilities[capability_cnt].state.value = value
      elseif (state == "led_color") then -- цвет SLS Led - конвертирую XY в RGB int 
        local value = fn.json_decode(update(true, state, device, dev_key))
        out[dev_key].capabilities[capability_cnt].state.value = fn.rgb_to_int(value.r, value.g, value.b)
      elseif (state == "led_effect") then -- эффекты SLS Led - вернуть значение effect
        local value = update(true, state, device, dev_key)
        if (value.effect) then
          out[dev_key].capabilities[capability_cnt].state.value = value.effect
        else
          out[dev_key].capabilities[capability_cnt].state.value = 0
        end
  
        -- свойства 
      elseif (state == "current") -- ток нагрузки
        or (state == "voltage") -- напряжение нагрузки
        or (state == "power") -- мощеость нагрузки
        or (state == "temperature") -- температура
        or (state == "humidity") -- влажность
        or (state == "battery") -- статус батареи
        then 
          local value = update(false, state, device, dev_key)
          out[dev_key].properties[property_cnt].state.value = value
      elseif (state == "pressure") then -- давление
          local value = update(false, state, device, dev_key)
          out[dev_key].properties[property_cnt].state.value = value * 0.75
      elseif (state == "SLS") then -- TODO обновления статуса led SLS
      end
    end
  end
  print(fn.json_encode(out))
end
