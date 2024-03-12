"""python ~/.dotfiles/config/.config/karabiner/old/keymap_generator.py
inspired from https://github.com/takeshi-yashiro/karabiner-elements-emacs
"""
import json
from argparse import ArgumentParser, Namespace
from pathlib import Path
from typing import Any

from helpers import ctrl_x_cmd, move_cmds, normal_cmd
from settings import cond_disable, cond_disable_desktop


def main(args: Namespace):
    """keymap jsonを生成して保存する

    Args:
        args (Namespace): コマンドライン引数
    """
    args.save_path.parent.mkdir(parents=True, exist_ok=True)
    kg = KeymapGenerator()
    output = kg.generate()
    with open(file=args.save_path, mode="w", encoding="utf-8") as f:
        json.dump(output, f, indent=4)


class KeymapGenerator:
    """Karabiner-Elementsのkeymapのjsonを生成する"""

    def generate(self) -> dict[str, Any]:
        """Karabiner-Elementsのkeymapのjsonを生成する

        Returns:
            dict[str, Any]: Karabiner-Elementsのkeymapのjson
        """
        manipulators = get_manipulators()
        # manipulatorsをkeymapのjsonに保存
        output = {
            "title": "Emacs key bindings (tyaba)",
            "maintainers": ["tyaba"],
            "rules": [
                {
                    "description": "Emacs key bindings (tyaba)",
                    "manipulators": manipulators,
                }
            ],
        }
        return output


def get_manipulators() -> list:
    """Karabiner-Elementsのkeymapのjsonのmanipulatorsを生成する

    Returns:
        list: manipulators
    """
    manipulators = []
    # alt + tab -> command + atmark
    # 同一アプリケーションの次のウィンドウに移動
    manipulators.append(
        normal_cmd(
            "tab",
            "2",
            src_modifiers=["option"],
            dst_modifiers=["left_command", "left_shift"],
            conditions=None,
        )
    )
    # C-x C-f, C-f
    manipulators.append(ctrl_x_cmd("f", "o"))
    manipulators.extend(move_cmds("f", "right_arrow", dst_modifiers=None))

    # C-x C-c (Chromeのみ Option+W のかわりに Option+Shift+W にマップ)
    c = ctrl_x_cmd("c", "w", dst_modifiers=["left_shift", "left_command"])
    c["conditions"][0] = {
        "type": "frontmost_application_if",
        "bundle_identifiers": ["^com\\.google\\.Chrome$"],
    }
    manipulators.append(c)
    manipulators.append(ctrl_x_cmd("c", "w"))

    # C-d
    manipulators.append(normal_cmd("d", "delete_forward", dst_modifiers=None))

    # C-h
    manipulators.append(normal_cmd("h", "delete_or_backspace", dst_modifiers=None))

    # C-k
    c = normal_cmd("k", "right_arrow", dst_modifiers=["left_shift", "left_command"])
    c["to"].append({"key_code": "x", "modifiers": "left_command"})
    manipulators.append(c)

    # C-o
    c = normal_cmd("o", "right_arrow")
    c["to"].append({"key_code": "return_or_enter"})
    c["to"].append({"key_code": "up_arrow"})
    manipulators.append(c)

    # C-g
    manipulators.append(normal_cmd("g", "escape", dst_modifiers=None))

    # C-j
    c = normal_cmd("j", "return_or_enter", dst_modifiers=None)
    c["to"].append({"key_code": "tab"})
    manipulators.append(c)

    # C-m
    manipulators.append(normal_cmd("m", "return_or_enter", dst_modifiers=None))

    # C-i
    manipulators.append(normal_cmd("m", "tab", dst_modifiers=None))

    # C-x C-s, C-s
    manipulators.append(ctrl_x_cmd("s", "s"))
    manipulators.append(normal_cmd("s", "f"))

    # C-r
    manipulators.append(normal_cmd("r", "f"))

    # C-w
    manipulators.append(normal_cmd("w", "x"))

    # M-w
    manipulators.append(normal_cmd("w", "c", src_modifiers=["option"]))

    # C-y
    manipulators.append(normal_cmd("y", "v"))

    # C-/
    manipulators.append(normal_cmd("slash", "z"))

    # C-a
    manipulators.extend(move_cmds("a", "left_arrow"))

    # C-e
    manipulators.extend(move_cmds("e", "right_arrow"))

    # C-p
    manipulators.extend(move_cmds("p", "up_arrow", dst_modifiers=None))

    # C-n
    manipulators.extend(move_cmds("n", "down_arrow", dst_modifiers=None))

    # C-b
    manipulators.extend(move_cmds("b", "left_arrow", dst_modifiers=None))

    # C-v
    manipulators.extend(move_cmds("v", "page_down", dst_modifiers=None))

    # M-v
    manipulators.extend(
        move_cmds("v", "page_up", src_modifiers=["option"], dst_modifiers=None)
    )

    # C-x h
    manipulators.append(ctrl_x_cmd("h", "a", src_modifiers=None))

    # C-x k
    manipulators.append(ctrl_x_cmd("k", "w", src_modifiers=None))

    # C-@, C-SPCを兼用
    for kc in ["spacebar", "open_bracket"]:
        c = normal_cmd(kc, None, clear_space=False)
        c["to"] = [{"set_variable": {"name": "C-SPC", "value": 1}}]
        c["conditions"].append({"type": "variable_unless", "name": "C-SPC", "value": 1})
        manipulators.append(c)

        # (マーク開始後に C-SPC した場合はそれまでの選択をESCキーを送出してキャンセルする)
        c = normal_cmd(kc, "escape", clear_space=False, dst_modifiers=None)
        c["conditions"].append({"type": "variable_if", "name": "C-SPC", "value": 1})
        manipulators.append(c)

    # C-x
    manipulators.append(
        {
            "type": "basic",
            "from": {"any": "key_code", "modifiers": {"optional": ["any"]}},
            "conditions": [{"type": "variable_if", "name": "C-x", "value": 1}]
            # 何も送らずに C-x 以降の命令を捨てている
        }
    )
    manipulators.append(
        {
            "type": "basic",
            "from": {
                "key_code": "x",
                "modifiers": {"mandatory": ["control"], "optional": ["caps_lock"]},
            },
            "to": [{"set_variable": {"name": "C-x", "value": 1}}],
            "to_delayed_action": {
                "to_if_invoked": [{"set_variable": {"name": "C-x", "value": 0}}],
                "to_if_canceled": [{"set_variable": {"name": "C-x", "value": 0}}],
            },
            "conditions": [cond_disable],
        }
    )

    # C-\ -> C-SPC (Toggle Eisu)
    manipulators.append(
        {
            "type": "basic",
            "from": {
                "key_code": "backslash",
                "modifiers": {"mandatory": ["left_control"], "optional": ["caps_lock"]},
            },
            "to": [
                {"key_code": "spacebar", "modifiers": ["left_control"]},
                {
                    "key_code": "vk_none",
                },
            ],
            "conditions": [cond_disable_desktop],
        }
    )

    # C-SPC -> C-@
    manipulators.append(
        {
            "type": "basic",
            "from": {
                "key_code": "spacebar",
                "modifiers": {"mandatory": ["control"], "optional": ["caps_lock"]},
            },
            "to": [{"key_code": "open_bracket", "modifiers": ["left_control"]}],
            "conditions": [cond_disable_desktop],
        }
    )

    # C-~ -> Spotlight
    manipulators.append(
        {
            "type": "basic",
            "from": {
                "key_code": "equal_sign",
                "modifiers": {"mandatory": ["control"], "optional": ["caps_lock"]},
            },
            "to": [{"key_code": "spacebar", "modifiers": ["left_command"]}],
        }
    )

    # C-t, C-z (Emacsキーバインドではないがそのままマップ)
    for kc in ["t", "z"]:
        manipulators.append(normal_cmd(kc, kc))

    # C-z (for VSCode only)
    c = normal_cmd("z", "slash", dst_modifiers=["left_control"])
    c["conditions"] = [
        {
            "type": "frontmost_application_if",
            "bundle_identifiers": ["^com\\.microsoft\\.VSCode$"],
        }
    ]
    manipulators.append(c)
    return manipulators


if __name__ == "__main__":
    parser = ArgumentParser()
    parser.add_argument(
        "--save-path",
        type=Path,
        help="myemacs.jsonの保存path",
        required=False,
        default=Path(
            "~/.config/karabiner/assets/complex_modifications/myemacs.json"
        ).expanduser(),
    )
    cmd_args = parser.parse_args()
    main(args=cmd_args)
