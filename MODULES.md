# 🧩 Написание своих модулей для Heroku

Heroku умеет загружать сторонние модули в виде одного Python-файла. В модуле
можно определить команды, вотчеры (реакцию на сообщения), инлайн-хендлеры,
конфигурацию и фоновые задачи — всё это даёт фреймворк `loader`.

> Сторонние модули полностью разблокированы — никаких «проверок» проходить
> не нужно.

---

## 📥 Установка модулей

| Команда | Что делает |
|---|---|
| `.dlm <url>` | Скачал и установил модуль по ссылке (алиас `.dlmod`) |
| `.loadmod` / `.lm` | Отправь `.py`-файл боту с командой в подписи — или в ответ на сообщение с файлом |
| `.dlmall` | Установить сразу все модули из репозитория модулей |
| `.ulm <ИмяМодуля>` | Выгрузить модуль |
| `.clearmodules` | Очистить все сторонние модули (с подтверждением) |
| `.addrepo <ссылка>` | Добавить сторонний репозиторий модулей (в нём должен быть `full.txt` с ссылками) |
| `.delrepo <ссылка>` | Убрать репозиторий |

Удобные ссылки: `raw.githubusercontent.com` (не `blob`-ссылки!). После загрузки
юзербот кэширует файл, поэтому модуль переживает перезагрузку бота.

---

## 🧪 Минимальный модуль

Любой модуль — это один `.py`-файл с классом, обёрнутым в `@loader.tds`:

```python
# ©️ Твоё имя, 2026
# This file is a part of Heroku Userbot
# 🔑 https://www.gnu.org/licenses/agpl-3.0.html

from herokutl.tl.types import Message

from .. import loader, utils


@loader.tds
class MyMod(loader.Module):
    """Описание модуля (попадёт в .help)"""

    strings = {"name": "MyMod"}

    @loader.command(ru_doc="Скажи привет")
    async def hello(self, message: Message):
        """- Пишет приветственное сообщение"""
        await utils.answer(message, "Привет! 👋")
```

Обязательные требования:

1. Класс декорируется `@loader.tds` — он переводит докстринги на язык юзербота.
2. `strings = {"name": ...}` — имя модуля обязательно.
3. Докстринг команды начинается с `- ` и описывает её для `.help`.
4. Файл в кодировке UTF-8.
5. `from .. import loader, utils` — так импортируется фреймворк (файл будет
   загружен относительно пакета `heroku`).

---

## 🪄 Команды

```python
@loader.command(ru_doc="Русское описание", alias="прив")
async def say(self, message: Message):
    """- Что команда делает (для .help)"""
    await utils.answer(message, self.strings["greet"].format("мир"))
```

- Имя команды = имя метода. Метод `hello` станет командой `.hello`.
- `ru_doc=` — описание для русского языка; для английского используется
  обычный докстринг.
- `alias="x"` и `aliases=("x", "y")` — альтернативные названия.
- Аргументы: `utils.get_args_raw(message)` — всё после команды одной строкой,
  `utils.get_args(message)` — список.
- `@loader.ratelimit` — ужесточает антифлуд для команды.

Строчки для разных языков:

```python
strings = {
    "name": "MyMod",
    "_cmd_doc_hello": "Description",
}
strings_ru = {"_cmd_doc_hello": "Описание команды привет"}
```

В коде все тексты берутся из `self.strings[...]` — они автоматически
подставляются из `strings_ru`, если язык юзербота русский.

---

## 👀 Вотчеры — реакции на сообщения

```python
@loader.watcher("out", "only_messages", regex=r"^/ping")
async def on_ping(self, message: Message):
    await utils.answer(message, "pong!")
```

Популярные теги: `in`, `out`, `only_commands`, `no_commands`, `only_pm`,
`no_pm`, `only_groups`, `only_channels`, `only_messages`, `editable`,
`no_media`, `only_media`, `contains="текст"`, `startswith=...`,
`endswith=...`, `regex=...`, `filter=lambda m: ...`, `from_id=...`,
`chat_id=...`. Полный список — в `heroku/loader.py`, функция `loader.tag()`.

---

## ⚙️ Конфиг модуля (появится в `.config`)

```python
def __init__(self):
    self.config = loader.ModuleConfig(
        loader.ConfigValue(
            "greeting",
            "Привет, {}!",
            lambda: "Шаблон приветствия ({}, это подстановка)",
            validator=loader.validators.String(),
        ),
        loader.ConfigValue(
            "count",
            1,
            lambda: "Сколько раз",
            validator=loader.validators.Integer(minimum=1, maximum=100),
        ),
    )
```

Чтение: `self.config["greeting"]`. Пользователь меняет из `.config`:

```
.config MyMod greeting "Привет, {}!"
.config MyMod count 2
```

Валидаторы: `String`, `Integer`, `Boolean`, `Float`, `Choice`, `Series`,
`DigitsString`, `Emoji`, `Link`, `RandomLink`, `Hidden` и др.
(см. `heroku/validators.py`).

---

## 💾 Хранилище данных модуля

Чтобы сохранить значение между перезагрузками:

```python
self.set("last_user", user_id)     # записать
self.get("last_user")              # прочитать
self.get("last_user", 0)           # с значением по умолчанию
```

- Значения хранятся в базе модуля и переживают перезагрузку юзербота.
- Прочие данные юзербота: `self.db.get("MyMod", "key", default)`.

---

## 🤖 Инлайн-кнопки и формы

Простая форма с кнопками:

```python
await self.inline.form(
    message=message,
    text="<b>Выбери действие</b>",
    reply_markup=[
        [
            {"text": "Сделать", "callback": self._do_it},
            {"text": "Отмена", "action": "close"},
        ]
    ],
)

async def _do_it(self, call):
    await call.edit("Сделано!")
```

Инлайн-хендлеры (доступны при вызове через встроенного инлайн-бота):

```python
@loader.inline_handler()
async def myquery(self: "MyMod", call, args):
    await call.answer([
        call.bot.form(
            text="Результат",
            reply_markup=[[{"text": "ОК", "action": "close"}]],
        )
    ])
```

---

## 🔁 Фоновые задачи

```python
@loader.loop(interval=60, autostart=True)
async def ticker(self):
    ...
```

- `interval` — период в секундах
- `autostart=True` — запустить сразу после загрузки модуля

---

## 🧨 Важные правила

1. **Никаких блокирующих вызовов в главном потоке** — `requests.get()` без
   таймаута вешает весь юзербот. Сеть делай через `aiohttp` или оборачивай в
   `asyncio.to_thread(...)`.
2. Команда принимает `herokutl.tl.types.Message` — не вызывай её напрямую у
   другого пользователя.
3. Модуль выполняется с теми же правами, что и сам юзербот: чужие модули
   читай перед установкой. Сторонний код может получить полный контроль
   над аккаунтом.
4. Никогда не пиши секреты (токены, пароли) внутри модуля — файлы попадают
   в кэш и бэкапы.

---

## 🚀 Готовый пример

Демо-модуль лежит в публичном репозитории:

```
.dlm https://raw.githubusercontent.com/FinikDev631/heroku-releases/main/modules/demo.py
```

Команды после установки: `.demo` (магический шар) и `.flip <текст>`.

Свой модуль не обязан лежать в сети — отправь `.py`-файл боту с подписью
`.loadmod`, и он будет установлен локально.

Хочешь опубликовать модуль для всех — отправь файл FinikDev631, он будет
добавлен в публичный репозиторий модулей.


## ⏱️ Паузы и интервалы в модулях

Массовые действия (спам, рассылка подарков, piar) часто нуждаются в настраиваемой паузе. Два правила работают лучше всего:

### 1. Флаг `-d <секунды>` в команде

Пользователь управляет паузой прямо из команды. Разбор флагов:

```python
# где-то в _parse: p = {"d": None, ...}
elif t in ("-in", "-at", "-d"):
    i += 1
    if i >= len(tokens):
        return None  # флаг без значения — покажем справку
    p[t[1:]] = tokens[i]
```

Проверка значения (запятая тоже валидна, границы 0..300):

```python
delay = None
if p["d"] is not None:
    delay = max(0.0, min(float(p["d"].replace(",", ".")), 300.0))
job = {..., "delay": delay}
```

Пауза после каждого шага, кроме последнего; без флага — значение из конфига:

```python
pause = job.get("delay")
pause = self.config["delay"] if pause is None else pause
if i < job["count"] - 1 and pause > 0:
    await asyncio.sleep(pause)
```

Использование: `.sendgift 101 @user x5 -d 2` — 5 подарков с паузой 2 сек.
Если флаг не писать — берётся настройка `delay` (по умолчанию 0, то есть без паузы).

### 2. Реальный интервал в цикле (как в модуле Piar)

Если твой модуль шлёт сообщения по кругу (`.piar`), интервал считай от **момента отправки**, а сбои и FloodWait обрабатывай в одном месте:

```python
while True:
    started = time.time()
    try:
        await self._client.send_message(chat_id, text)
    except FloodWaitError as e:
        await asyncio.sleep(e.duration + 1)
        continue
    except Exception:
        logger.exception("Failed to send")

    elapsed = time.time() - started
    await asyncio.sleep(max(1, interval - elapsed))
```

**Не вставляй искусственные паузы**: Heroku больше не добавляет к отправке защиту-паузу по умолчанию (антиспам-модуль APILimiter выключен, включается только вручную через `.api_fw_protection`). Если после отключения лимитера какой-то цикл всё ещё тормозит — это пауза в самом модуле.
