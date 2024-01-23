# Генерация ключей и сертификатов для работы с Rutoken Tech
Внешние зависимости находятся в [Рутокен SDK](http://www.rutoken.ru/developers/sdk/)

Необходимые файлы:
* openssl/bin/3.0/openssl-3.0/openssl-tool-3.0/macos-x86_64+arm64/* (Rutoken SDK).
* openssl/bin/3.0/rtengine-3.0/ios+iossim+macos-x86_64+arm64-xcframework/rtengine.xcframework (Rutoken SDK).

## Настройка
* Положите rtengine.xcframework в директорию `prepareCredentials` в корне проекта;
* Положите директорию с бинарными файлами OpenSSL (`macos-x86_64+arm64`) в директорию `prepareCredentials` в корне проекта;

Чтобы openssl динамически загружал rtengine укажите в уже имеющимся в директории `prepareCredentials` файле конфигурации путь до библиотеки `rtengine`:
```
openssl_conf = openssl_def

[ openssl_def ]
    engines = engine_section

[ engine_section ]
    rtengine = gost_section

[ gost_section ]
    dynamic_path = /path/to/rtengine.xcframework/macos-arm64_x86_64/rtengine.framework/rtengine
```
* Запустите скрипт `generateCredentials.sh`