"""karabinerの設定を生成するためのヘルパー関数を提供するモジュール"""
from typing import Any

from settings import clear_spc, cond_disable


def cmd(
    src: str,
    dst: str | None,
    src_modifiers: list[str] | None = ["control"],
    src_modifiers_opt: list[str] | None = ["caps_lock"],
    dst_modifiers: list[str] | None = ["left_command"],
    conditions: list[dict[str, Any]] | None = [cond_disable],
) -> dict[str, Any]:
    """cmd+src -> dstのマッピングを生成する"""
    data = {
        "type": "basic",
        "from": {
            "key_code": src,
            "modifiers": {
                # "mandatory": src_modifiers,
                # "optional": src_modifiers_opt
            },
        },
        "to": [{}],
        "conditions": conditions if conditions is not None else [],
    }
    if dst is not None:
        data["to"] = [
            {
                "key_code": dst,
                # "modifiers": dst_modifiers
            }
        ]
        if dst_modifiers is not None:
            data["to"][0]["modifiers"] = dst_modifiers

    if src_modifiers is not None:
        data["from"]["modifiers"]["mandatory"] = src_modifiers
    if src_modifiers_opt is not None:
        data["from"]["modifiers"]["optional"] = src_modifiers_opt
    return data


# C-x
def ctrl_x_cmd(
    src: str,
    dst: str | None,
    src_modifiers: list[str] | None = ["control"],
    src_modifiers_opt: list[str] | None = ["caps_lock"],
    dst_modifiers: list[str] | None = ["left_command"],
):
    """C-x系のコマンド"""
    data = cmd(
        src,
        dst,
        src_modifiers=src_modifiers,
        src_modifiers_opt=src_modifiers_opt,
        dst_modifiers=dst_modifiers,
    )
    data["conditions"].append({"type": "variable_if", "name": "C-x", "value": 1})
    data["to"].append(clear_spc)
    return data


def normal_cmd(
    src: str,
    dst: str | None,
    clear_space: bool = True,
    src_modifiers: list[str] | None = ["control"],
    src_modifiers_opt: list[str] | None = ["caps_lock"],
    dst_modifiers: list[str] | None = ["left_command"],
    conditions: list[dict[str, Any]] | None = [cond_disable],
):
    """通常のコマンド"""
    data = cmd(
        src,
        dst,
        src_modifiers=src_modifiers,
        src_modifiers_opt=src_modifiers_opt,
        dst_modifiers=dst_modifiers,
        conditions=conditions,
    )
    data["conditions"].append({"type": "variable_unless", "name": "C-x", "value": 1})
    if clear_space:
        data["to"].append(clear_spc)
    return data


def move_cmds(
    src: str,
    dst: str | None,
    src_modifiers: list[str] | None = ["control"],
    src_modifiers_opt: list[str] | None = ["caps_lock", "shift"],
    dst_modifiers: list[str] | None = ["left_command"],
):
    """移動系のコマンド (マークがついているときにだけShiftを付加する)"""
    # マーク（C-SPC)がついていないときはそのまま
    nospc = normal_cmd(
        src,
        dst,
        clear_space=False,
        src_modifiers=src_modifiers,
        src_modifiers_opt=src_modifiers_opt,
        dst_modifiers=dst_modifiers,
    )
    nospc["conditions"].append({"type": "variable_unless", "name": "C-SPC", "value": 1})

    # マーク(C-SPC)がついているときは、Shiftを追加
    if dst_modifiers is None:
        dst_modifiers = []
    dst_modifiers_shift = dst_modifiers + ["left_shift"]
    spc = normal_cmd(
        src,
        dst,
        clear_space=False,
        src_modifiers=src_modifiers,
        src_modifiers_opt=src_modifiers_opt,
        dst_modifiers=dst_modifiers_shift,
    )
    spc["conditions"].append({"type": "variable_if", "name": "C-SPC", "value": 1})

    return [nospc, spc]
