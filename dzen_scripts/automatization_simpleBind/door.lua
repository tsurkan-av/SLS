-- если в скрипт пришло значение FALSE, значит открыли дверь
if (Event.State.Value == false) then
   -- то включить свет
  zigbee.set("0xA4C138D8A539DB0F", "state", "ON")
-- если в скрипт пришло значение FALSE, значит закрыли дверь
else
  -- задать/продлить таймер на выключение света через время timer
  scripts.setTimer("#zigbee.set('0xA4C138D8A539DB0F', 'state', 'OFF')", os.time() + 300)
end
