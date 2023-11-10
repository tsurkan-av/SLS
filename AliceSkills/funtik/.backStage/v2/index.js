/*
 TODO Обработать Недоступность SLS
 TODO Обработать таймаут ф-ции
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
const slsToken = `?token=${process.env.slsToken}`;

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
			slsApiParam = `&action=evalFile&path=/funtik.lua&param=${devicesQueryJson}`;
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
			slsApiParam = `&action=evalFile&path=/funtik.lua&param=${devicesQueryJson}`;
			url = slsUrl + slsApiFn + slsToken + slsApiParam;
			devicesSLS = await httpGet(url, true);
			if (devicesSLS.success) {
				devicesSLS = isJson(devicesSLS.result);
			}
			result = {
				request_id,
				payload: {"devices": devicesSLS},
				response: {end_session: false}
			};
			break;
		}
		case "discovery": {
			// получаю funtikData.json из SLS
			slsApiFn = "storage";
			slsApiParam = "&path=/int/funtikData.json";
			url = slsUrl + slsApiFn + slsToken + slsApiParam;
			console.log(url);
			const devicesGate = await httpGet(url, true);
			result = {
				request_id,
				payload: {
					"user_id": user_id,
					"devices": devicesGate.devices
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
