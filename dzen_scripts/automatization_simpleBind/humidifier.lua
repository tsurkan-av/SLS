-- задаем диапазон тишины
-- начало тишины
local startHour = 22 -- часы 
local startMin = 0 -- минуты
-- конец тишины
local endHour = 5 -- часы 
local endMin = 50 -- минуты

-- получаем текущее время
local nowHour = Event.Time.hour -- часы
local nowMin = Event.Time.min -- минуты

-- преобразуем часы:минуты в минуты
local startRange = startHour * 60 + startMin -- начало тишины в минутах
local endRange = endHour * 60 + endMin -- конец тишины в минутах
local nowTime = nowHour * 60 + nowMin -- текущее время в минутах

-- проверяем: попадает ли текущее время в заданный диапазон
-- переменная - флаг - попадает ли время в диапазон 
local inRange = false
-- проверяем, переходит ли искомый диапазон через 0:00 часов 
if startRange > endRange then
  -- если переходит, то считаем так: Если ("время начала тишины" <= "текущее время" <= 0:00) или (0:00 <= "текущее время" <= "время конца тишины") то текущее время попало в диапазон
  if ((startRange <= nowTime and nowTime <= 24*60) or (0 <= nowTime and nowTime <= endRange)) then
	inRange = true
  end
else
  -- если НЕ переходит через 0:00 часов, то считаем так: Если ("время начала тишины" <= "текущее время" <= "время конца тишины") то текущее время попало в диапазон
  if (startRange <= x and x <= endRange) then
	inRange = true
  end 
end

-- если текущее время попало в диапазон тишины
if inRange then -- значит ночь 22:00 .. 5:50
  -- то выключаем увлажнитель
  zigbee.set("0xA4C138E143F426BA", "state", "OFF") -- то выключить
-- если текущее время НЕ попало в диапазон тишины
else
  -- управляем увлажнителем в зависимости от влажности от 40% до 60%
  if (Event.State.Value < 40) then -- включение: если вланость < минимума 
    zigbee.set("0xA4C138E143F426BA", "state", "ON")
  elseif (Event.State.Value > 60) then
    zigbee.set("0xA4C138E143F426BA", "state", "OFF") -- выключение: если вланость > максимума
  end
end