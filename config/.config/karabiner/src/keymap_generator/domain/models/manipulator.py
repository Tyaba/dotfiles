"""Karabiner-Elementsのfromとtoのkeyのマッピングのスキーマ
"""
from typing import Literal, Optional

from pydantic import BaseModel, Field


class FromModifiers(BaseModel):
    """変換元の修飾キーのスキーマ"""

    mandatory: Optional[list[str]] = Field(
        default=None, title="必須の修飾キー", examples=["left_shift", "right_shift"]
    )
    optional: Optional[list[str]] = Field(
        default=None, title="任意の修飾キー", examples=["left_shift", "right_shift"]
    )


class From(BaseModel):
    """変換元のキーストロークのスキーマ"""

    key_code: Optional[str] = Field(
        default=None, title="変換元のキーコード", examples=["a", "b"]
    )
    modifiers: FromModifiers = Field(
        default=None,
        title="変換元の修飾キー",
    )
    any: Optional[Literal["key_code", "cosumer_key_code", "pointing_button"]] = Field(
        default=None,
        title="一括で変換する際の変換元のキーコードのくくり",
        examples=["key_code", "cosumer_key_code", "pointing_button"],
    )


class SetVariable(BaseModel):
    """フラグをセットするためのスキーマ"""

    name: str = Field(default=..., title="フラグの名前", examples=["C-x", "C-SPC"])
    value: int = Field(default=..., title="フラグの値", examples=[0, 1])


class ToItem(BaseModel):
    """変換先のキーストロークのスキーマ"""

    key_code: Optional[str] = Field(
        default=None, title="変換先のキーコード", examples=["a", "b"]
    )
    modifiers: Optional[str | list[str]] = Field(
        default=None, title="変換先の修飾キー", examples=["left_shift", "right_shift"]
    )
    set_variable: Optional[SetVariable] = Field(
        default=None,
        title="フラグをセットする",
    )


class Condition(BaseModel):
    """変換を行う条件のスキーマ"""

    type: str = Field(
        default=...,
        title="条件のタイプ",
        examples=[
            "frontmost_application_if",
            "frontmost_application_unless",
            "device_if",
            "device_unless",
            "device_exists_if",
            "device_exists_unless",
            "keyboard_type_if",
            "keyboard_type_unless",
            "input_source_if",
            "input_source_unless",
            "variable_if",
            "variable_unless",
            "event_changed_if",
            "event_changed_unless",
        ],
    )
    name: Optional[str] = Field(default=None, title="フラグの名前", examples=["C-x", "C-SPC"])
    value: Optional[int] = Field(default=None, title="フラグの値", examples=[0, 1])
    bundle_identifiers: Optional[list[str]] = Field(
        default=None, title="条件の引数", examples=[["com.apple.Terminal"]]
    )


class ToDelayedAction(BaseModel):
    """変換先のキーストロークを遅延して実行するためのスキーマ"""

    to_if_invoked: list[ToItem] = Field(
        default=..., title="遅延中に他のキーが入力されなかった場合のキーストローク"
    )
    to_if_canceled: list[ToItem] = Field(default=..., title="遅延中に他のキーが入力された場合のキーストローク")


class Manipulator(BaseModel):
    """Karabiner-Elementsのfromとtoのkeyのマッピングのスキーマ"""

    from_: From = Field(
        ...,
        title="変換元のキーストローク",
    )
    to: Optional[list[ToItem]] = Field(
        default=None,
        title="変換先のキーストローク",
    )
    type: Literal["basic"] = Field(
        default="basic",
        title="manipulatorのタイプ",
        examples=["basic"],
    )
    conditions: Optional[list[Condition]] = Field(
        default=None,
        title="変換を行う条件",
    )
    to_delayed_action: Optional[ToDelayedAction] = Field(
        default=None,
        title="遅れて発動させるキーストローク",
    )
