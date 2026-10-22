# 📱 Установка на телефон (Android)

Termux не поддерживается — часть зависимостей не собрать на Android. Ставим полноценный Linux через **UserLAnd** (Ubuntu на Android, без root).

## 1. Установи UserLAnd

1. Google Play → **UserLAnd** → установи
2. Открой UserLAnd → создай сессию **Ubuntu**
3. Дождись запуска терминала (первый старт ~5 минут)
4. Если просит пароль — задай любой

## 2. Установи Heroku

В терминале UserLAnd (Ubuntu) — одна команда:

\\ash
bash <(curl -fsSL https://raw.githubusercontent.com/FinikDev631/heroku-releases/master/install.sh)
\
Скрипт сам установит всё нужное, получит код и запустит бота. Останется ввести номер телефона и код из Telegram.

## 3. Запуск после перезагрузки телефона

UserLAnd останавливает Linux вместе с Android. Для повторного запуска:

1. Открой UserLAnd → сессия Ubuntu
2. В терминале:

\\ash
bash <(curl -fsSL https://raw.githubusercontent.com/FinikDev631/heroku-releases/master/install.sh)
\
Скрипт запомнит, что бот уже установлен, и просто запустит его. Если вышла новая версия — он обновится и запустит её.

> Android может убивать фоновый процесс. Отключи оптимизацию батареи для UserLAnd (Настройки → Батарея → Не ограничивать).

## Альтернатива: VDS

Если есть любой Linux-сервер (Ubuntu/Debian) — установи той же командой по SSH, без UserLAnd. На VDS бот живёт постоянно.

## Удаление

\\ash
rm -rf ~/Heroku
\