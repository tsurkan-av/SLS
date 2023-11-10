Документация в разработке. Планируемая дата публикации: до конца ноября 2023

# Навык Алисы для голосового управления устройствами SLS и не только

##  Введение

Для голосового управления устройствами SLS я пробовал навык YaHa, когда еще был Home Assistant. Затем освоил навык Домовенок Кузя. Но он мне тоже по ряду причин не подошел. Так родилась идея собственного навыка и я приступил к разработке.

## Концепция управления умным домом

[Описание концепции в документации Яндекс](https://yandex.ru/dev/dialogs/smart-home/doc/concepts/general-concept.html)

![](/AliceSkills/funtik/img/Ya_smartHome_cheme.svg)

Здесь:

- Alice - голосовой помощник, например в колонке
- Yandex App - Приложение  Дом с Алисой
- Yandex Smart Home - платформа умного дома.
- Provider - в нашем случае шлюз SLS
- Adapter API - промежуточный сервер, доступный из сети интернет как для Provider так и для Yandex Smart Home по протоколу HTTPS. Я остановился на сервисе [Yandex Cloud Functions](https://cloud.yandex.ru/docs/functions/) (YCF)

## Настройка

### Настройка функции YCF



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