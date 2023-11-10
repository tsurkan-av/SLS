const allBtnsNode = document.querySelectorAll('.btn.btn-territory.btn-round-left');
const allBtns = [...allBtnsNode];

const licId = document.querySelector('#lic-id').innerText;

const popup = document.querySelector('#meters-popup');

const ipuType = document.querySelector('#ipu-type');
const ipuNum = document.querySelector('#ipu-num');
const ipuZone = document.querySelector('#ipu-zone');
const ipuDate = document.querySelector('#ipu-date');


const input = document.querySelector('#ipu-meter');
const errorField = document.querySelector('#error-field');


const sendBtn = document.querySelector('#meter-send');



const sendMeterUrl = '/include/api/meters/addReadingsIpuForLic.ajax.php';


function insertPopupValues(type, num, date, minValue, zone, maxValue) {
	/*
	type - похоже что ipuName - ХВС/ГВС
	num - номер счетчика
	date - today -	let date = new Date();
				let yyyy = date.getFullYear();
				let mm = date.getMonth() + 1; // Months start at 0!
				let dd = date.getDate();
				if (dd < 10) dd = '0' + dd;
				if (mm < 10) mm = '0' + mm;
				let today = dd + '.' + mm + '.' + yyyy;
	
	*/
	ipuType.setAttribute('value', `${type}`);
	ipuNum.setAttribute('value', `${num}`);
	ipuZone.setAttribute('value', `${zone}`);
	ipuDate.setAttribute('value', `${date}`);

	input.setAttribute('placeholder', `min: ${minValue}`);
	input.setAttribute('min', `${minValue}`);
	input.setAttribute('max', `${maxValue}`);
}
let date = new Date();
let yyyy = date.getFullYear();
let mm = date.getMonth() + 1; // Months start at 0!
let dd = date.getDate();
if (dd < 10) dd = '0' + dd;
if (mm < 10) mm = '0' + mm;
let today = dd + '.' + mm + '.' + yyyy;

allBtns.forEach((btn, index) => {
	// удалить!!!!
	btn.removeAttribute('disabled');

	btn.addEventListener('click', function () {
		document.querySelector('body').classList.add('lock');

		let meters = this.closest('.meters');

		let minValue = this.getAttribute('data-min');
		let maxValue = this.getAttribute('data-max');
		let zone = this.getAttribute('data-zone');
		let name = this.getAttribute('data-name');


		let closestNamePrev = this.closest('.meters__right-column');
		let closestName = closestNamePrev.querySelector('.meters__name').innerText;
		let onlyNumbers = closestName.replace('Счётчик ', '');

		insertPopupValues(name, String(onlyNumbers), today, minValue, zone, maxValue); 
		/*
		name - ?
		onlyNumbers - номер счетчика
		today -	let date = new Date();
				let yyyy = date.getFullYear();
				let mm = date.getMonth() + 1; // Months start at 0!
				let dd = date.getDate();
				if (dd < 10) dd = '0' + dd;
				if (mm < 10) mm = '0' + mm;
				let today = dd + '.' + mm + '.' + yyyy;
		zone - понятно) Общая 

		
		
		*/

		showPopup(this, index);
	})
});


sendBtn.addEventListener('click', () => {
	BX.showWait();
	$.ajax({
		type: "POST",
		url: sendMeterUrl,
		data: {
			licId: `${licId}`,
			data: `${input.value}`,
			ipuName: `${ipuType.value}`,
			ipuNum: `${ipuNum.value}`,
			ipuZone: `${ipuZone.value}`,
			ipuDate: `${ipuDate.value}`,
		},
		success: function (res) {
			if (res.code && res.code == "200") {
				//console.log(data);
				closePopup();
				showResultPopup('ok');
			} else {
				console.log(data);
				closePopup();
				showResultPopup();
			}
		},
		error: function (err) {
			//console.log(data);
			console.log(err);
			closePopup();
			showResultPopup();
		},
		complete: function () {
			BX.closeWait();
		}
	});
});