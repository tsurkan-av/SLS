test history
/***** TODO *****
* Обработать Недоступность SLS
*/
/** 
* ответ при проблеме серта Keenetic 
* {"errorMessage":"request to https://sls... failed, reason: Hostname/IP does not match certificate's altnames: Host: sls.tsurkan.keenetic.pro. is not in the cert's altnames: DNS:*.keenetic.pro, DNS:keenetic.pro","errorType":"FetchError"}
****
{"headers": {"authorization": "0","request_id": "discovery_id"},"request_type": "discovery"}
{"headers":{"authorization":"0","request_id":"query_id"},"request_type":"query","payload":{"devices":[{"id":"0xA4C138FD68EAA226"}]}}
{"headers":{"authorization":"0","request_id":"action_id"},"request_type":"action","payload":{"devices":[{"id":"0xA4C138FD68EAA226","capabilities":[{"type":"devices.capabilities.color_setting","state":{"instance":"rgb","value":16749000 }},{"type":"devices.capabilities.on_off","state":{"instance":"on","value":false }}]}]}}
*/
const fetch = require("node-fetch"); // импорт node-fetch
const slsUrl = "https://sls.tsurkan.keenetic.pro/api/";
const slsToken = "?token=" + process.env.slsToken;

module.exports.handler = async (event, context) => {
	const request_type 	= event.request_type;
	const request_id 	= event.headers.request_id;
	const user_id		= "SLS";
    let slsApiFn, slsApiParam, url, devicesSLS, result;
	
	switch (request_type) {
		case "action": {
			// в теории достаточно ответа, что всё хорошо
			// проблемы разбирать на стороне SLS в логе
			// тогда ждать ответа от SLS не требуется
			const devicesQuery	= {
				"request_type": request_type,
				"request_data": event.payload.devices
			};
			const devicesAlice 	= [];
			const replacer = new RegExp('"', 'g')
			const devicesQueryJson = JSON.stringify(devicesQuery).replace(replacer, '\\"');
			slsApiFn = "scripts";
			slsApiParam = "&action=evalFile&path=/funtik.lua&param=" + devicesQueryJson;
			url = slsUrl + slsApiFn + slsToken + slsApiParam;
			// запрос на управление. ответ не ждать, т.к. вроде бы не нужен он
			devicesSLS = httpGet(url, true);
			Object.entries(event.payload.devices).forEach((entry) => {
				const [key, device] = entry;
				devicesAlice.push({
					"id": device.id,
					"action_result": {"status": "DONE"}
				});
			});
			result = {
				request_id,
				payload: {"devices": devicesAlice},
				response: {end_session: false}
			};
			break;
		}
		case "query": {
			const devicesQuery	= {
				"request_type": request_type,
				"request_data": event.payload.devices
			};
			const devicesAlice 	= [];
			const replacer = new RegExp('"', 'g')
			const devicesQueryJson = JSON.stringify(devicesQuery).replace(replacer, '\\"');
			slsApiFn = "scripts";
			slsApiParam = "&action=evalFile&path=/funtik.lua&param=" + devicesQueryJson;
			url = slsUrl + slsApiFn + slsToken + slsApiParam;
			devicesSLS = await httpGet(url, true);
			if (devicesSLS.success) {
				devicesSLS = isJson(devicesSLS.result);
				if (devicesSLS) {
					Object.entries(devicesSLS).forEach((entry) => {
						const [key, device] = entry;
						devicesAlice.push(updDeviceAlice(device));
					});
				} 
			}
			result = {
				request_id,
				payload: {"devices": devicesAlice},
				response: {end_session: false}
			};
			break;
		}
		case "discovery": {
			// получаю funtikData.json из SLS
			slsApiFn = "storage";
			slsApiParam = "&path=/int/funtikData.json";
			url = slsUrl + slsApiFn + slsToken + slsApiParam;
			const devicesGate = await httpGet(url, true);
			// формирую список устройств
			const devicesAlice = [];
			Object.entries(devicesGate.devices).forEach((entry) => {
				const [key, device] = entry;
				devicesAlice.push(getDeviceAlice(device, key));
			});
			result = {
				request_id,
				payload: {
					"user_id": user_id,
					"devices": devicesAlice
				},
				response: {end_session: false}
			};
			break;
		}
		default:
		break;
	}
	
    return result;
};

/***************** JSON Parse with valid check off JSON string **********/
function isJson(str) {
	try {
		return JSON.parse(str); 
	} catch (e) {
		return false;
	}
}
/***************** HTTP Request to SLS **********/
async function httpGet(url, mode) {
	// mode - режим запроса: JSON = true; text = false
    const response = await fetch(url);
    if (response.status !== 200) {
        throw new Error('Network response was not 200', response);
    }
	if (mode) {
		return response.json();
	} else {
		return response.text();
	}
}
/***************** Create New Device Payload **********/
function getDeviceAlice(device, deviceID) {
	const capabilities = [];
	const properties = [];
	switch (device.type) {
		case "light": { // Лампа
			capabilities.push({
				"type": "devices.capabilities.range",
				"retrievable": true,
				"parameters": {
					"instance": "brightness",
					"unit": "unit.percent",
					"range": {"min": 0, "max": 100, "precision": 1}
				}
			});
			capabilities.push({
				"type": "devices.capabilities.color_setting",
				"retrievable": true,
				"parameters": device.color_setting
			});
			capabilities.push({
				"type": "devices.capabilities.on_off",
				"retrievable": true
			});
			break;
		}
		case "sensor": { // датчик 
			
			break;
		}
		default:
		break;
	}
	return {
		"id": device.ieeeAddr,
		"name": device.name,
		"description": device.friendly_name,
		"type": "devices.types.light",
		"room": device.room,
		"capabilities": capabilities
	};
}
/***************** Create Update Device Payload **********/
function updDeviceAlice(device) {
	const deviceType = device.type;
	const deviceColorScheme = device.color;
	let capabilities, color, type;
	switch (deviceType) {
		case 'light': { // Лампа
			capabilities = [];
			capabilities.push({
				"type": "devices.capabilities.range",
				"state": {
					"instance": "brightness",
					"value": device.brightness
				}
			});
			capabilities.push({
				"type": "devices.capabilities.on_off",
				"state": {
					"instance": "on",
					"value": device.state == "ON" ? true : false
				}
			});
			capabilities.push({
				"type": "devices.capabilities.color_setting",
				"state": 
				{
					"instance": "temperature_k",
					"value": device.color_temp
				}
			});
			// если лампа может управлят цветом, то добавляем цветовую модель
			if (device.color) {
				/*
				let color = isJson(device.color);
				if (color) {
					color = rgbToInt(cie_to_rgb(color.x, color.y));
				} else {
					color = 0;
				}
				*/
				capabilities.push({
					"type": "devices.capabilities.color_setting",
					"state": 
					{
						"instance": "rgb",
						"value": device.color
					}
				});
			}
			break;
		}
		default:
		break;
	}
	return {
		"id": device.id,
		"capabilities": capabilities,
	};
}
