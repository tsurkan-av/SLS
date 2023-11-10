--print('-------' .. os.time(), os.freeMem() .. '-----------')

-- Как получить IAM-токен для аккаунта Yandex https://cloud.yandex.ru/docs/iam/operations/iam-token/create
-- токен нужен для авторизации в приватной в-ции Яндекс. Поскольку ф-ця SLS http.request2() пока не умеет передавать заголовки ф-ци публичная
local tokenYaOAuth = '' 
local tokenSLS = '' -- в меню SLS Settings -> Users включить Secure API и забрать токен в поле Token

local fn = (loadfile "/int/func.lib")()

-- получаю данный счетчиков в кубах 
local meters = '{\z
	\"23-256124\": {\"value\": ' .. (zigbee.value('0x00124B0027AEBF18', 'counter_1')/1000) .. ', \"ipuSend\": \"N\"},\z
	\"23-364334\": {\"value\": ' .. (zigbee.value('0x00124B0027AEBF18', 'counter_2')/1000) .. ', \"ipuSend\": \"N\"},\z
	\"23-286253\": {\"value\": ' .. (zigbee.value('0x00124B0027AEBF1C', 'counter_1')/1000) .. ', \"ipuSend\": \"N\"},\z
	\"23-367214\": {\"value\": ' .. (zigbee.value('0x00124B0027AEBF1C', 'counter_2')/1000) .. ', \"ipuSend\": \"N\"}}'

-- получаю IAM токен
local url = 'https://iam.api.cloud.yandex.net/iam/v1/tokens'
local body = '{\"yandexPassportOauthToken\": \"' .. tokenYaOAuth .. '\"}'
local method = 'POST'
local headers = ''
local tokenYa = (fn.json_decode(http.request2(url, method, headers, body))).iamToken

url = 'https://functions.yandexcloud.net/d4epl4qniindb7kh7702'
body = '{\"auth_sls\": \"' .. tokenSLS .. '\", \"meters\": ' .. meters .. '}'
headers = 'Authorization: Bearer ' .. tokenYa .. '\n'
local response = http.request2(url, method, headers, body)
-- {"duration": 40.2, "auth": "OK", "meters": {"23-256124": {"value": 1.19, "dateOld": "01.10.2023", "valueOld": "0.183", "ipuZone": "\u041e\u0431\u0449\u0430\u044f", "ipuName": "\u0413\u0412\u0421"}, "23-364334": {"value": 2.66, "dateOld": "01.10.2023", "valueOld": "0.286", "ipuZone": "\u041e\u0431\u0449\u0430\u044f", "ipuName": "\u0425\u0412\u0421"}, "23-286253": {"value": 9.03, "dateOld": "01.10.2023", "valueOld": "0.513", "ipuZone": "\u041e\u0431\u0449\u0430\u044f", "ipuName": "\u0413\u0412\u0421"}, "23-367214": {"value": 7.91, "dateOld": "01.10.2023", "valueOld": "0.558", "ipuZone": "\u041e\u0431\u0449\u0430\u044f", "ipuName": "\u0425\u0412\u0421"}}}
print(response)

-- если response короткий, то проблема с вызовом ф-ции, например Error: Code 499 Message: request cancelled 
if #response < 10 then
	-- запускаю скрипт через 5 минут
	-- TODO включить для запуска по расписанию
	--scripts.setTimer("sendMeters", os.time() + 300)
	telegram.send('Отправка счетчиков - Ошибка: пустой response')
else
	-- TODO включить для запуска по расписанию
	--scripts.setTimer("sendMeters", "0 2 15 * *", 7)
	response = fn.json_decode(response)
	
	if response['errorMessage'] then
		telegram.send('Отправка счетчиков - ошибка выполнения ф-ции')
		print('sendMeters.lua: ' .. response['errorMessage'])
	else 
		local dateOld
		msg = 'Показания с сайта УК:\n'
		for key, meter in pairs(response['meters']) do 
		  msg = msg .. key .. ': ' .. meter['valueOld'] .. '\n'
		  dateOld = meter['dateOld']
		end
		msg = msg .. 'Переданы ' .. dateOld .. '\n\n'

		msg = '\n' .. msg .. 'Переданные показания:\n'
		for key, meter in pairs(response['meters']) do 
		  msg = msg .. key .. ': ' .. meter['value'] .. '\n'
		end
		
		for key, meter in pairs(response['result']) do 
			if meter['status'] == 'error' then 
				msg = msg .. key .. ': ' .. meter['status'] .. ': ' .. meter['text'] .. '\n'
				print('sendMeters.lua: ' .. meter['text'])
			else
				msg = msg .. key .. ': ' .. meter['status'] .. '\n'
			end
		end
		telegram.send(msg)
	end
end

