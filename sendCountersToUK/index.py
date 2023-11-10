import time
import datetime

start_time = time.time()

import os
import json
import requests
import base64

from bs4 import BeautifulSoup

url = 'https://lk.ek-territory.ru/'

def handler(event, context):
    # проверка авторизации SLS
    # проверяю наличие параметра auth_sls в запросе и его равенство переменной окружения SLS_API_KEY (ключ из sls)

    # при вызове из теста - event может не быть
    # при вызове с снаружи event есть всегда и может быть закодирован в Base64
    # Если функция вызывается с заголовком Content-Type: application/json, то содержимое body останется в исходном формате (значение параметра isBase64Encoded: false)
    # TODO доработать, когда http.request2() сможет отправлять заголовки
    if event['isBase64Encoded']:
        body = json.loads(base64.b64decode(event['body']))
        if not body.get('auth_sls') == os.environ["SLS_API_KEY"]:
            return {
                'statusCode': 200,
                'body': 'auth sls error',
            }
    # для завершения скрипта код далее
    '''
    return {
        'statusCode': 200,
        'body': 'stop script',
    }
    '''
    # далее код жля проверки из теста
    '''
    if not ((type(event) is dict) and (event.get('auth_sls') != None) and (event.get('auth_sls') == os.environ["SLS_API_KEY"])):
        return {
            'statusCode': 200,
            'body': 'auth sls error',
        }
    '''
    # создаю сессию
    session = requests.Session()
    
    # авторизация и получение страницы с данными по счечикам для парсинга
    data = {
        "AUTH_FORM": "Y",
        "TYPE": "AUTH",
        "USER_LOGIN": os.environ["USER_LOGIN"],
        "USER_PASSWORD": os.environ["USER_PASSWORD"]
    }

    response = session.post(url + 'meters/?login=yes', data = data)
    
    # проверка авторизации на сайте УК
    # если в куках есть BITRIX_SM_GUEST_ID значит авторизовались
    if response.cookies.get('BITRIX_SM_GUEST_ID'):
        expires = next(x for x in response.cookies if x.name == 'BITRIX_SM_GUEST_ID').expires
        # authStatus = datetime.fromtimestamp(expires)
        authStatus = 'OK'
        
        # парсинг страницы - достаю данны по счетчикам
        main = BeautifulSoup(response.text, "html.parser").main
        licId = int(main.find('div', id='lic-id').text)
        
        def get_js_object(str):
            temp = str.split()
            for i in range(len(temp)):
                if 'ipuNum' in temp[i]:
                    ipuNum: str = temp[(i+1)].rstrip(",").replace("'","")
                if 'ipuZone' in temp[i]:
                    ipuZone: str = temp[(i+1)].rstrip(",").replace("'","")
                if 'ipuName' in temp[i]:
                    ipuName: str = temp[(i+1)].rstrip(",").replace("'","")
            return {'ipuNum': ipuNum, 'ipuZone': ipuZone, 'ipuName': ipuName}
        
        #oldPage = soup
        # meters = {}
        for meter in main.find_all('section', class_='meters'):
            # получаю ipuNum (Номер), ipuZone и ipuName (ХВС/ГВС)
            ipuData = get_js_object(meter.script.text)
            # получаю значению и дату его передачи
            meterData = meter.find('p', class_='meters__last-update')
            meterData.br.extract()
            meterData = meterData.text.split()
            # значение 
            meterValue = meterData[1].lstrip("принятые:")
            # дата передачи значения
            meterDate = meterData[len(meterData)-1]
            if ipuData['ipuNum'] in body['meters']:
                body['meters'][ipuData['ipuNum']].update({'dateOld': meterDate, 'valueOld': meterValue, 'ipuZone': ipuData['ipuZone'], 'ipuName': ipuData['ipuName']})
        
        # отправка показаний
        # TODO в цикле тправлять на след месяц
        send_result = {}
        current_date = datetime.datetime.now().strftime('%d.%m.%Y')
        for meterNum, meterData in body['meters'].items():
            data = {
                "licId": licId, #  хз. - одно значение для всех счетчиков
                "data": meterData['value'], # показание счетчика
                "ipuName": meterData['ipuName'], # ХВС/ГВС
                "ipuNum": meterNum, # номер счетчика
                "ipuZone": meterData['ipuZone'], # хз - одинаково для всех счетчиков
                "ipuDate": current_date, 
            }
            print(data)
            # TODO сделать обработку ответа и вернуть его в SLS (пока обрабатываю в SLS)
            # {"status":"error","text":"Не корректный набор данных","code":406,"data":[]}
            #response = session.post(url + '/include/api/meters/addReadingsIpuForLic.ajax.php', data = data)
            if meterData['ipuSend'] == 'Y':
                response = session.post(url + '/include/api/meters/addReadingsIpuForLic.ajax.php', data = data)
                send_result[meterNum] = response.json()
            else:
                send_result[meterNum] = {'status': 'sending is OFF in SLS'}
                

    else:
        authStatus = 'Fail'
    
    # закрываю сессию
    session.close()
    
    print(send_result)
    # ответ функции
    return {
        'statusCode': 200,
        'body': json.dumps(
            {
                'duration': round((time.time() - start_time), 1),
                'auth': "{}".format(authStatus),
                'meters': body['meters'],
                'result': send_result
            })
    }
