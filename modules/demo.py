# В©пёЏ FinikDev631, 2026
# Demo custom module for Heroku userbot (StaticGram fork)
# You can redistribute it and/or modify it under the terms of the GNU AGPLv3
# рџ”‘ https://www.gnu.org/licenses/agpl-3.0.html

import random

from herokutl.tl.types import Message

from .. import loader, utils


@loader.tds
class Demo(loader.Module):
    """Demo custom module вЂ” shows what third-party modules can do"""

    strings = {"name": "Demo"}

    async def client_ready(self, client, db):
        self._db = db

    @loader.command(ru_doc="РџСЂРёРјРµСЂ: СЃС‡С‘С‚С‡РёРє РёР»Рё СЃР»СѓС‡Р°Р№РЅС‹Р№ СЃРѕРІРµС‚")
    async def demo(self, message: Message):
        """- Magic 8-ball style answer"""
        answers = [
            "Р”Р°, РѕРїСЂРµРґРµР»С‘РЅРЅРѕ рџЄђ",
            "Р”Р°Р¶Рµ РЅРµ РґСѓРјР°Р№",
            "РЎРїСЂРѕСЃРё РїРѕР·Р¶Рµ",
            "50/50",
            "РњРѕР№ РѕС‚РІРµС‚ вЂ” РґР°",
            "Р‘РµР· С€Р°РЅСЃРѕРІ",
        ]
        await utils.answer(message, f"рџЋ± {random.choice(answers)}")

    @loader.command(ru_doc="РџРµСЂРµРІРµСЂРЅСѓС‚СЊ С‚РµРєСЃС‚")
    async def flip(self, message: Message):
        """- Flip the given text"""
        args = utils.get_args_raw(message) or "рџЄђ"
        await utils.answer(message, args[::-1])
