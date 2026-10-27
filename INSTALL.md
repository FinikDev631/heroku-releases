# 📱 Установка на телефон (Android)

Termux не поддерживается — часть зависимостей не собрать на Android. Ставим полноценный Linux через **UserLAnd** (Ubuntu на Android, без root).

## 1. Установи UserLAnd

1. Google Play → **UserLAnd** → установи
2. Открой UserLAnd → создай сессию **Ubuntu**
3. Дождись запуска терминала (первый старт ~5 минут)
4. Если просит пароль — задай любой

## 2. Установи Heroku

В терминале UserLAnd (Ubuntu) — две команды:

```bash
sudo curl -fsSL https://raw.githubusercontent.com/FinikDev631/heroku-releases/master/install.sh -o install.sh
sudo bash install.sh
```

Скрипт сам установит всё нужное, получит код и запустит бота. Останется ввести номер телефона и код из Telegram.

> Обязательно второй командой — `bash install.sh`, а не `bash <(curl ...)`. Иначе у бота не будет «клавиатуры» и он не сможет спросить API ID / номер телефона (выдаст `Cancelled`).

## Проблемы и решения

### `curl: (77) error adding trust anchors` / ошибки сертификата

Битые/пустые сертификаты в свежем образе. Чинится так:

```bash
sudo apt-get update
sudo apt-get install -y ca-certificates
sudo update-ca-certificates
```

Повтори установку. Если и `apt-get update` ругается на сертификаты:

```bash
sudo apt-get -o Acquire::https::Verify-Peer=false update
sudo apt-get install -y --allow-unauthenticated ca-certificates
sudo update-ca-certificates
```

### `Termux is not supported`

Ты открыл установщик в Termux — он не поддерживается. Ставь через UserLAnd (см. шаг 1).

### Другие ошибки

Пришлю скриншот ошибки в официальный чат — разберём.

## 3. Запуск после перезагрузки телефона

UserLAnd останавливает Linux вместе с Android. Для повторного запуска:

1. Открой UserLAnd → сессия Ubuntu
2. Если установщика нет в папке — скачай: `sudo curl -fsSL https://raw.githubusercontent.com/FinikDev631/heroku-releases/master/install.sh -o install.sh`
3. Запусти: `sudo bash install.sh`

Скрипт запомнит, что Heroku уже установлен, и просто запустит его. Если вышла новая версия — он обновится и запустит её.

> Не запускай через `bash <(curl ...)` — у бота не будет «клавиатуры», и он не сможет спросить API ID или код (`Cancelled`).

> Android может убивать фоновый процесс. Отключи оптимизацию батареи для UserLAnd (Настройки → Батарея → Не ограничивать).

## Альтернатива: VDS

Если есть любой Linux-сервер (Ubuntu/Debian) — установи той же командой по SSH, без UserLAnd. На VDS бот живёт постоянно.

## Удаление

```bash
rm -rf ~/Heroku
```
