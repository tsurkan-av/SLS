local devices = {
	-- name - ieeeAddr, nwAddr, freindly_name устройств для контроля
	-- uptime -  допустимый период отвала в минутах
	-- в каждой строке данные по одному устройству
	{name = "cnt_kitchen", uptime = 180}, -- 0x00124B0027AEBF18
	{name = "cnt_toilet", uptime = 180}  -- 0x00124B0027AEBF1C
}

-- обход массива devices 
for key, device in pairs(devices) do
  -- при каждой итерации берем очередную пару name/uptime 
  -- для каждого устройства name, проверяем состояние last_seen и если оно больше uptime, отправляем сообщение в Telegram
  if math.ceil((os.time() - zigbee.value(device['name'], 'last_seen'))/60) > device['uptime'] then 
    -- подготовка сообщения
    msg = 'Error: ' .. device['name'] .. ' is down!'
	-- отправка в Telegram 
    telegram.send(msg)
  end
end