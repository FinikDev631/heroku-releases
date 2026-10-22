# 📱 Установка на телефон (Android)

Termux не поддерживается — часть зависимостей не собрать под Android. Ставим полноценный Linux через **UserLAnd** (эмуляция Ubuntu на Android, работает без root).

## 1. Создай токен GitHub

Репозиторий приватный, для установки каждому нужен свой токен:

1. Зайди на https://github.com/settings/tokens?type=beta
2. **Generate new token**, имя любое, срок любой
3. В **Repository access** выбери **Only select repositories** → `FinikDev631/heroku`
4. В правах достаточно **Contents: Read-only**
5. Скопируй токен (`github_pat_...`)

> Токен нужен ДО начала установки — попроси его у владельца, если у тебя нет доступа к настройкам репозитория.

## 2. Установи UserLAnd

1. Google Play → **UserLAnd** → установи
2. Открой UserLAnd → **Apps** → **Kali/Ubuntu** → собственно создай сессию
3. Дождись запуска терминала (первый старт ~5 минут)
4. Если просит пароль — задай любой

## 3. Установи Heroku

В терминале UserLAnd (Ubuntu):

```bash
export HEROKU_GIT_TOKEN=токен_из_шага_1
bash <(curl -fsSL https://raw.githubusercontent.com/FinikDev631/heroku/master/install.sh)
```

Скрипт сам установит всё нужное, получит код и запустит бота. Останется ввести номер телефона и код из Telegram.

## 4. Запуск после перезагрузки телефона

UserLAnd останавливает Linux вместе с Android. Для повторного запуска:

1. Открой UserLAnd → сессия Ubuntu
2. В терминале:

```bash
export HEROKU_GIT_TOKEN=токен
bash install.sh
```

`install.sh` запомнит, что бот уже установлен, и просто запустит его.

> Постоянно открытый Android может убивать фоновый процесс. Отключи оптимизацию батареи для UserLAnd (Настройки → Батарея → Не ограничивать).

## Альтернатива: VDS

Если у тебя есть любой Linux-сервер (Ubuntu/Debian) — установи той же командой из шага 3 прямо по SSH, без UserLAnd. На VDS бот живёт постоянно.

## Обновления

При выходе новой версии бот пришлёт уведомление в Telegram со списком изменений. Обновить:

```bash
export HEROKU_GIT_TOKEN=токен
bash install.sh
```

Скрипт подтянет свежий код и запустит обновлённую версию.

## Удаление

В терминале Linux:

```bash
rm -rf ~/Heroku
```
