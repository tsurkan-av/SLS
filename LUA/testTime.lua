local f = { _version = "0.1.1" }

--[[ Управление zigbee устройством с проверкой статуса и вызовом Get в конвертере
*	device:     ieeeAddr, nwkAddr, FN
* state:      состояние
* value:      значение
* Опции:      проверка значения изменяемого состояния 
* checkState: true - если требуется проверка состояния. Если текущее значение не равно value 
--]]
-- TODO - доделать возврат result
local function zigbeeAction(device, state, value, checkState, checkGet)
  local result = {}
  if checkState then
    if checkGet then
      if (zigbee.get(device, state)) then
        result['checkGet'] = true
      else
        result['checkGet'] = false
      end
    end
    result['oldValue'] = zigbee.value(device, state)
    if (result['oldValue'] ~= value) then
      zigbee.set(device, state, value)
      result['action'] = true
      result['checkState'] = true
      return result
    else
      result['action'] = false
      result['checkState'] = false
      return result
    end
  else
    zigbee.set(device, state, value)
    result['action'] = true
  end
end

--[[ Попадает ли чмсло в диапазон 
*	mode: num    - inRange('num', x, startRange, endRange)
*	mode: clock  - inRange('clock', nowHour, startHour, endHour[, xMin, startMin, endMin]) --]]
local function inRange(mode, x, startRange, endRange, nowMin, startMin, endMin)
  if (mode == 'clock') then
    if not xMin then xMin = 0 end
    if not startMin then startMin = 0 end
    if not endMin then endMin = 0 end
    x = x * 60 + xMin
    startRange = startRange * 60 + startMin
    endRange = endRange * 60 + endMin
    if startRange > endRange then
      if ((startRange <= x and x <= 24*60) or (0 <= x and x <= endRange)) then
        return true
      end
    else
      if (startRange <= x and x <= endRange) then
        return true
      end 
    end
  end
  if (mode == 'num') then
    if (startRange <= x and x <= endRange) then
      return true
    end
  end
  return false
end

return f