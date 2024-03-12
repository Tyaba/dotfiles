"""KeymapGeneratorのインターフェース"""
from abc import ABCMeta, abstractmethod

from pydantic import BaseModel, Field

from keymap_generator.domain.models.keymap import Keymap, Rule
from keymap_generator.settings import get_settings

settings = get_settings()


class GenerateInput(BaseModel):
    """keymap生成の入力"""

    title: str = Field(
        default=settings.keymap_title,
        title="keymapのタイトル",
        description="Karabiner-Elementsのkeymapのタイトル",
        examples=["Emacs key bindings (tyaba)"],
    )
    maintainers: list[str] = Field(
        default=settings.keymap_maintainers,
        title="メンテナーs",
        description="Karabiner-Elementsのkeymapのメンテナー",
        examples=[["tyaba"]],
    )
    rules: list[Rule] = Field(
        default=...,
        title="キーストローク変換ルールs",
        description="Karabiner-Elementsのkeymapのmanipulatorとその説明のリスト",
    )


class GenerateOutput(BaseModel):
    """keymap生成の出力"""

    keymap: Keymap = Field(
        default=...,
        title="keymap",
        description="Karabiner-Elementsのkeymapのjson",
    )


class KeymapGeneratorInterface(metaclass=ABCMeta):
    """Karabiner-Elementsのkeymapのjsonを生成する"""

    @abstractmethod
    def generate(self, generate_input: GenerateInput) -> GenerateOutput:
        """Karabiner-Elementsのkeymapのjsonを生成する

        Returns:
            Keymap: Karabiner-Elementsのkeymapのjson
        """
