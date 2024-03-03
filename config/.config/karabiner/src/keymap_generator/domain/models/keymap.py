"""Karabiner-Elementsでそのまま使用可能なjsonファイルのスキーマ"""
from pydantic import BaseModel, Field

from keymap_generator.domain.models.manipulator import Manipulator
from keymap_generator.settings import get_settings

settings = get_settings()


class Rule(BaseModel):
    """fromとtoのkeyのマッピングであるmanipulatorのリストとその説明"""

    description: str = Field(
        default="",
        title="キーストローク変換ルールの説明",
        description="Karabiner-Elementsのkeymapのmanipulatorの説明",
    )
    manipulators: list[Manipulator] = Field(
        default=...,
        title="キーストローク変換ルールs",
        description="Karabiner-Elementsのkeymapのmanipulatorとその説明のリスト",
    )


class Keymap(BaseModel):
    """Karabiner-Elementsのkeymapとして使用可能なjson"""

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

    def dump_with_rename(self, indent: int = 4, **kwargs) -> str:  # type: ignore
        """Karabiner-Elementsのkeymapのとして使用可能なjsonを生成する
        fromというフィールドはpythonの予約語なので、from_をfromに変更してから出力する
        Returns:
            dict[str, Any]: Karabiner-Elementsのkeymapのjson
        """
        data: str = self.model_dump_json(indent=indent, **kwargs)
        data = data.replace('"from_":', '"from":')
        data = data.replace('"conditions": null,', "")
        return data
