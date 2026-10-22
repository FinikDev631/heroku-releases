# ©️ FinikDev631, 2026
# This file is a part of Heroku Userbot
# You can redistribute it and/or modify it under the terms of the GNU AGPLv3
# 🔑 https://www.gnu.org/licenses/agpl-3.0.html

import asyncio
import logging

from herokutl.tl.types import Message

from .. import loader, utils

logger = logging.getLogger(__name__)


@loader.tds
class PiarMod(loader.Module):
    """Автоматическая рассылка сообщений с заданным интервалом"""

    strings = {
        "name": "Piar",
    }

    def __init__(self):
        self._running = False
        self._task = None

    async def client_ready(self):
        self._running = False

    def _task_done(self, future):
        self._task = None
        self._running = False

    async def _loop(self, message: Message, interval: int, text: str):
        try:
            while True:
                try:
                    await utils.answer(message, text)
                except Exception:
                    logger.exception("Failed to send piar message")

                await asyncio.sleep(interval)
        except asyncio.CancelledError:
            pass

    @loader.command(
        ru_doc=(
            "<интервал> <текст> — отправлять текст в этот чат каждые N секунд"
            " (интервал по умолчанию — 10 сек)\n"
            "Без аргументов или «стоп» — остановить рассылку"
        ),
        en_doc=(
            "<interval> <text> — send text to this chat every N seconds (default 10)\n"
            "No args or 'stop' — stop the spam"
        ),
    )
    async def piar(self, message: Message):
        """Запустить/остановить периодическую рассылку"""
        args = utils.get_args_raw(message)

        if not args or args.strip().lower() in {"стоп", "stop", "отмена", "cancel"}:
            if self._running and self._task:
                self._task.cancel()
                self._task = None
                self._running = False
                await utils.answer(message, "<b>🛑 Рассылка остановлена</b>")
            else:
                await utils.answer(
                    message,
                    "<b>Напиши: <code>.piar &lt;интервал&gt; &lt;текст&gt;</code>"
                    "</b>\n<i>Интервал по умолчанию — 10 секунд</i>",
                )
            return

        interval = 10
        text = args

        first_word, _, rest = args.partition(" ")
        if rest and first_word.isdigit():
            interval = max(int(first_word), 1)
            text = rest

        if self._running and self._task:
            self._task.cancel()
            self._task = None

        self._running = True
        self._task = asyncio.ensure_future(self._loop(message, interval, text))
        self._task.add_done_callback(self._task_done)

        await utils.answer(
            message,
            "<b>📣 Рассылка запущена</b>\n"
            f"<b> Интервал:</b> <code>{interval} сек</code>\n"
            "<i>Остановить: <code>.piar стоп</code> (или просто <code>.piar</code>)</i>",
        )

    async def on_unload(self):
        if self._task:
            self._task.cancel()
            self._task = None
        self._running = False

    async def on_stop(self):
        if self._task:
            self._task.cancel()
            self._task = None
        self._running = False
