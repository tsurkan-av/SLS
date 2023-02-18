let startedWebSockets = false;
let wsTimer = 0;
let influx;
const WebSocket = require('ws');
const url = 'ws://192.168.1.247:81/log';
const wsSocket = new WebSocket(url);
const Influx = require('influx');

/*
wsSocket.onopen = () => {
	console.log('Hello')
}
*/

wsSocket.binaryType = 'blob';

wsSocket.onopen = function (j) {
	console.log('WS connected');
	startedWebSockets = true;
	clearTimeout(wsTimer);
	subscribeToDevices(); // подписка на обновление состояния устройств
	influxConn(); // соединение с InfluxDB
	
};

wsSocket.onmessage = function (message) { // при обновлении состояния устройства, обновить значение в карточке функцией deviceUpdate()
	//console.log(`WS data`);
	const data = JSON.parse(message.data);
	console.log(`Action: ${data.category} Data: `, data);
	//influxWrite(123); // запись в БД
};

wsSocket.onclose = function (j) {
	startedWebSockets = false;
	wsTimer = setTimeout('startWebSockets();', 5 * 1000);
	console.log('WS disconnected');
};
// подписка на изменения состояния устройств и объектов
function subscribeToDevices() {
	console.log('Sending menu subscription request...');
	wsSocket.send(JSON.stringify({
		action: 'subscribe',
		category: 'zigbee',
	}));
	wsSocket.send(JSON.stringify({
		action: 'subscribe',
		category: 'objects',
	}));
  return false;
}

// инициализация соединения с InfluxDB
function influxConn() {
	influx = new Influx.InfluxDB({
	 host: 'localhost',
	 database: 'sls',
	 schema: [
	   {
		 measurement: metric,
		 fields: {
		   ieeeAddr: Influx.FieldType.STRING,
		   duration: Influx.FieldType.INTEGER
		 },
		 tags: [
		   'host'
		 ]
	   }
	 ]
	})
}
// запись в InfluxDB
function influxWrite(duration) {
	influx.writePoints([
	  {
		measurement: 'response_times',
		tags: { host: 'hostname' },
		fields: { duration, path: 'path' },
	  }
	]).then(() => {
	  return influx.query(`
		select * from response_times
		where host = $<host>
		order by time desc
		limit 10
	  `, {
		 placeholders: {
		   host: 'hostname'
		 }
	  })
	}).then(rows => {
	  rows.forEach(row => console.log(`A request to ${row.path} took ${row.duration}ms`))
	})

}