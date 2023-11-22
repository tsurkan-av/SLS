# Навык Алисы для голосового управления устройствами SLS и не только

Для голосового управления устройствами [SLS](https://slsys.github.io/basic) я пробовал навык YaHa, когда еще был Home Assistant. Затем освоил навык [Домовенок Кузя](https://github.com/slsys/Gateway/blob/master/docs/lua_doc/voice_ctrl_Kuzia.md). Но он мне тоже по ряду причин не подошел. Так родилась идея собственного навыка и я приступил к разработке.

## Что даст прохождение этого квеста

<!-- [Видео:](http://www.youtube.com/watch?v=Me6aceoHY_E) -->

[![Видео](http://img.youtube.com/vi/Me6aceoHY_E/0.jpg)](http://www.youtube.com/watch?v=Me6aceoHY_E)

Картинка кликабельна - под ней видео)
<!-- https://youtu.be/Me6aceoHY_E -->

## Поддерживаемые устройства

Поддержка реализована только для устройств, который у меня в наличии

- Лампа, с поддержкой управления цветом, яркостью и цветовой температурой
- Розетка, с передачей свойств: power, current, voltage и управлением опциями: backlight_mode, power_on_behavior
- Реле
- Датчик климата, с передачей свойств: temperature, humidity, pressure в одном устройстве (в отличие от Кузи)

Также, для батарейных устройств передается состояние батареи 



## Концепция управления умным домом Яндекс

[Описание концепции в документации Яндекс](https://yandex.ru/dev/dialogs/smart-home/doc/concepts/general-concept.html)

![](/AliceSkills/funtik/img/Ya_smartHome_cheme.svg)

Здесь:

- Alice - голосовой помощник, например в колонке
- Yandex App - Приложение  Дом с Алисой
- Yandex Smart Home - платформа умного дома.
- Provider - в нашем случае шлюз SLS
- Adapter API - промежуточный сервер, доступный из сети интернет как для Provider так и для Yandex Smart Home по протоколу HTTPS. Я остановился на сервисе [Yandex Cloud Functions](https://cloud.yandex.ru/docs/functions/) (YCF)

## Настройка со стороны Яндекс

### Настройка функции YCF

- подготовить скрипт [index.js](/AliceSkills/funtik/index.js) с функцией
- подготовить файл зависимостей [package.json](/AliceSkills/funtik/package.json)
- [создать функцию YCF](https://cloud.yandex.ru/docs/functions/quickstart/create-function/node-function-quickstart) со следующими настройками
  - Среда выполнения: `Node.js 16`
  - Способ: `редактор кода`
  - Точка входа: `index.handler`
  - Таймаут, c: 5
  - Память: дефолтных 128Мб достаточно 
  - Переменные окружения:
    - slsToken: API-токен SLS
  - создать файл `index.js` и скопировать в него содержимое скрипта [index.js](/AliceSkills/funtik/index.js) с функцией
  - создать файл `package.json` и скопировать в него содержимое файла зависимостей [package.json](/AliceSkills/funtik/package.json)
- Сохранить изменения: сохранение запустит сборку новой версии функции

### Настройка авторизации OAuth в Яндекс ID 

[Описание в документации Яндекс](https://yandex.ru/dev/id/doc/ru/register-client)

[Создать приложение](https://oauth.yandex.ru/client/new/id) с такими настройкам:

![](/AliceSkills/funtik/img/OUAuthAPPSettings.png)

![](/AliceSkills/funtik/img/OUAuthAPPSettings2.png)

В итоге получите приложение с такими настройками

![](/AliceSkills/funtik/img/OUAuthAPP.png)

Здесь для нас важны поля `ClientID` и `Client secret`

### Создание навыка Умного дома Яндекс

[Описание на сайте Яндекс](https://yandex.ru/dev/dialogs/smart-home/doc/start.html)

[Создать новый диалог](https://dialogs.yandex.ru/developer) типа `Умный дом` с такими настройками:

![](/AliceSkills/funtik/img/dialogSettingsGeneral.png)

![](/AliceSkills/funtik/img/dialogSettingsPublic.png)

Здесь в поле `Backend` указывается:

- Функция в Яндекс Облаке - выбираем свою функцию из списка
- Endpoint URL - адрес обработчика на выделенном сервере

Далее необходимо настроить авторизацию на вкладке `Связка аккаунтов` так:

![](/AliceSkills/funtik/img/dialogSettingsOauth.png)

Здесь Идентификатор и Секрет приложения - это `ClientID` и `Client secret` полученные при настройке авторизации OAuth в Яндекс ID
 
После чего на вкладке `Общие сведения` можно опубликовать черновик и навык готов к работе.

## Настройка со стороны SLS

###  Загрузка библиотеки функций

Для данного проекта была собрана [библиотека](/LUA/func.lib) с функциями:

- JSON. Слегка доработанные функции json.lua от [rxi](https://github.com/rxi/json.lua)
  - json_encode() - добавлена возможность простановки escape символов и точность округления
  - json_decode() - добавлена возможность удаления escape символов
- Convert CIE to RGB - преобразование цвета CIE -> RGB
- Convert RGB to CIE - преобразование цвета RGB -> CIE
- Convert Integer to RGB - преобразование цвета INT -> RGB
- Convert RGB to Integer - преобразование цвета RGB -> INT

Необходимо в SLS создать файл `func.lib` и вставить содержимое [файла](/LUA/func.lib)

### Загрузка списка устройств для голосового управления

Создать в SLS файл описания устройств для взаимодействия с УДЯ [funtikData.json](/AliceSkills/funtik/funtikData.json) в формате [Яндекс API](https://yandex.ru/dev/dialogs/smart-home/doc/reference/get-devices-jrpc.html)

### Загрузка скрипта - обработчика вызовов УДЯ

Создать в SLS файл `funtik.lua` и вставить в него содержимое [файла](/AliceSkills/funtik/funtik.lua)

## Управление устройствами

Теперь можно открыть приложение Умный дом с Алисой и добавить устройства SLS:

- нажать + 
- выбрать кнопку Устройства умного дома
- в поиске (значок лупы) найти навык по имени, которое задали при его создании
- нажать кнопку Обновить список устройств

Если всё сделано верно, то в приложение будут загружены устройства SLS.

## Отладка

В случае каких либо проблем, для поиска ошибок можно использовать:

- [лог SLS](https://github.com/slsys/Gateway/blob/master/docs/lua_doc/logging.md)
- лог функции YCF или логи своего сервера, если функцию развернули на нем
- лог запросов на вкладке Тестирование в [Яндекс.Диалоги](https://dialogs.yandex.ru/developer)



---

_PS. Вы можете поддержать меня [здесь](https://www.tinkoff.ru/cf/3y9klHwhFuV).  Любые суммы, даже самые маленькие мотивируют на разработку чего-то нового и улучшение уже существующего._