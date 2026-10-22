# ©️ Твоё имя, 2026
# This file is a part of Heroku Userbot
# 🔑 https://www.gnu.org/licenses/agpl-3.0.html

import random
import time

from herokutl.tl.types import Message

from .. import loader, utils


@loader.tds
class DickMeterMod(loader.Module):
    """дилдак-метр с изменой и топами"""

    strings = {
        "name": "DickMeter",
        "no_top": "<b>пока никого нет в топе</b>",
        "top_header": "<b>топ дилдаков:</b>\n",
        "cheat_grow": "измена! дилдак вырос на <b>{grow} см</b>, теперь <b>{size} см</b>",
        "activated": "<b>измена активирована в этом чате</b>",
        "deactivated": "<b>измена выключена в этом чате</b>",
        "wait": "<b>ты уже мерил, приходи через {mins} мин</b>",
    }

    strings_ru = {
        "no_top": "<b>пока никого нет в топе</b>",
        "top_header": "<b>топ дилдаков:</b>\n",
        "cheat_grow": "измена! дилдак вырос на <b>{grow} см</b>, теперь <b>{size} см</b>",
        "activated": "<b>измена активирована в этом чате</b>",
        "deactivated": "<b>измена выключена в этом чате</b>",
        "wait": "<b>ты уже мерил, приходи через {mins} мин</b>",
    }

    def __init__(self):
        self.config = loader.ModuleConfig(
            loader.ConfigValue(
                "min_grow",
                1,
                lambda: "минимальный прирост за измену (см)",
                validator=loader.validators.Integer(minimum=1, maximum=50),
            ),
            loader.ConfigValue(
                "max_grow",
                10,
                lambda: "максимальный прирост за измену (см)",
                validator=loader.validators.Integer(minimum=1, maximum=50),
            ),
            loader.ConfigValue(
                "cooldown",
                3600,
                lambda: "перерыв между замерами в секундах (3600 = 1 час)",
                validator=loader.validators.Integer(minimum=60),
            ),
        )

    def _chat_key(self, message: Message) -> str:
        """уникальный ключ для чата/топика"""
        chat_id = utils.get_chat_id(message)
        topic = getattr(message, "reply_to_top_id", None) or getattr(message, "reply_to_msg_id", None)
        return f"{chat_id}:{topic or 0}"

    @loader.command(ru_doc="померить дилдак")
    async def дик(self, message: Message):
        """- меряет дилдак и показывает текущую длину"""
        uid = str(message.sender_id)
        size = self.get(uid + "_size", 0)
        last = self.get(uid + "_last", 0)
        now = time.time()
        if now - last < self.config["cooldown"]:
            mins = int((self.config["cooldown"] - (now - last)) // 60) + 1
            await utils.answer(message, self.strings["wait"].format(mins=mins))
            return
        if size == 0:
            new_size = random.randint(1, 30)
            self.set(uid + "_size", new_size)
            self.set(uid + "_last", now)
            await utils.answer(message, f"твой дилдак вырос до <b>{new_size} см</b>")
        else:
            grow = random.randint(1, 10)
            new_size = size + grow
            self.set(uid + "_size", new_size)
            self.set(uid + "_last", now)
            await utils.answer(
                message,
                f"дилдак вырос на <b>{grow} см</b>, теперь <b>{new_size} см</b>",
            )

    @loader.command(ru_doc="топ дилдаков")
    async def диктоп(self, message: Message):
        """- показывает топ по длине дилдака"""
        raw = self._db.get(self.strings["name"], {}) or {}
        data = {
            int(k[:-5]): v
            for k, v in raw.items()
            if k.endswith("_size") and k[:-5].isdigit()
        }
        if not data:
            await utils.answer(message, self.strings["no_top"])
            return
        top = sorted(data.items(), key=lambda x: x[1], reverse=True)[:10]
        lines = []
        for i, (uid, size) in enumerate(top, 1):
            user = await self.client.get_entity(uid)
            name = getattr(user, "first_name", None) or "unknown"
            lines.append(f"{i}. {name} — {size} см")
        await utils.answer(message, self.strings["top_header"] + "\n".join(lines))

    @loader.command(ru_doc="включить/выключить измену в этом чате")
    async def дактивация(self, message: Message):
        """- активирует измену в текущем чате/топике (только для тебя)"""
        key = "cheat_" + self._chat_key(message)
        if self.get(key, False):
            self.set(key, False)
            await utils.answer(message, self.strings["deactivated"])
        else:
            self.set(key, True)
            await utils.answer(message, self.strings["activated"])

    @loader.watcher("in", "only_messages", "no_commands")
    async def watcher(self, message: Message):
        """реагирует на ответы — измена растит дилдак"""
        if not message.is_reply:
            return
        key = "cheat_" + self._chat_key(message)
        if not self.get(key, False):
            return
        reply = await message.get_reply_message()
        if reply.sender_id != message.sender_id:
            return
        uid = str(reply.sender_id)
        grow = random.randint(self.config["min_grow"], self.config["max_grow"])
        new_size = self.get(uid + "_size", 0) + grow
        self.set(uid + "_size", new_size)
        await utils.answer(
            message,
            self.strings["cheat_grow"].format(grow=grow, size=new_size),
        )
