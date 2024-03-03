from keymap_generator.domain.models.keymap import Rule
from keymap_generator.domain.models.manipulator import (
    Condition,
    From,
    FromModifiers,
    Manipulator,
    SetVariable,
    ToDelayedAction,
    ToItem,
)
from keymap_generator.settings import get_settings
from keymap_generator.usecase.rules.decorators import (
    clear_space,
    emacs_exclude,
    only_when_ctrl_x,
)

settings = get_settings()


@only_when_ctrl_x
@clear_space
@emacs_exclude
def undo_rule() -> Rule:
    """undo"""
    rule = Rule(
        description="undo",
        manipulators=[
            Manipulator(
                from_=From(
                    key_code="u",
                    modifiers=FromModifiers(
                        mandatory=["left_control"],
                    ),
                ),
                to=[
                    ToItem(
                        key_code="z",
                        modifiers=["left_command"],
                    )
                ],
            )
        ],
    )
    return rule


@only_when_ctrl_x
@clear_space
@emacs_exclude
def save_rule() -> Rule:
    """保存する"""
    rule = Rule(
        description="保存",
        manipulators=[
            Manipulator(
                from_=From(
                    key_code="s",
                    modifiers=FromModifiers(
                        mandatory=["left_control"],
                    ),
                ),
                to=[
                    ToItem(
                        key_code="s",
                        modifiers=["left_command"],
                    )
                ],
            )
        ],
    )
    return rule


@only_when_ctrl_x
@clear_space
@emacs_exclude
def delete_window_rule() -> Rule:
    """ウィンドウを閉じる"""
    rule = Rule(
        description="ウィンドウを閉じる",
        manipulators=[
            Manipulator(
                from_=From(
                    key_code="c",
                    modifiers=FromModifiers(
                        mandatory=["left_control"],
                    ),
                ),
                to=[
                    ToItem(
                        key_code="w",
                        modifiers=["left_command"],
                    )
                ],
            ),
            Manipulator(
                from_=From(
                    key_code="c",
                    modifiers=FromModifiers(
                        mandatory=["left_control"],
                    ),
                ),
                to=[
                    ToItem(
                        key_code="w",
                        modifiers=["left_command", "left_shift"],
                    )
                ],
                conditions=[
                    Condition(
                        type="frontmost_application_if",
                        bundle_identifiers=["^com\\.google\\.Chrome$"],
                    )
                ],
            ),
        ],
    )
    return rule


@only_when_ctrl_x
@clear_space
@emacs_exclude
def open_file_rule() -> Rule:
    """ファイルを開く"""
    rule = Rule(
        description="ファイルを開く",
        manipulators=[
            Manipulator(
                from_=From(
                    key_code="f",
                    modifiers=FromModifiers(
                        mandatory=["left_control"],
                    ),
                ),
                to=[
                    ToItem(
                        key_code="o",
                    )
                ],
            )
        ],
    )
    return rule


@emacs_exclude
def ctrl_x_rule() -> Rule:
    """ctrl xした時にフラグを一瞬有効にする"""
    rule = Rule(
        description="ctrl xした時にフラグを一瞬有効にする",
        manipulators=[
            # C-x が押された時にフラグを立てる
            Manipulator(
                from_=From(
                    key_code="x",
                    modifiers=FromModifiers(
                        mandatory=["control"], optional=["caps_lock"]
                    ),
                ),
                to=[ToItem(set_variable=SetVariable(name="C-x", value=1))],
                to_delayed_action=ToDelayedAction(
                    to_if_invoked=[
                        ToItem(set_variable=SetVariable(name="C-x", value=0))
                    ],
                    to_if_canceled=[
                        ToItem(set_variable=SetVariable(name="C-x", value=0))
                    ],
                ),
            ),
            # 何も送らずに C-x 以降の命令を捨てている
            Manipulator(
                from_=From(any="key_code", modifiers=FromModifiers(optional=["any"])),
                conditions=[Condition(type="variable_if", name="C-x", value=1)],
            ),
        ],
    )
    return rule


def generate_ctrl_x_rules() -> list[Rule]:
    """ctrl-x系のルールを生成する

    Returns:
        list[Rule]: ctrl-x系のルール
    """
    rules = [
        undo_rule(),
        save_rule(),
        delete_window_rule(),
        open_file_rule(),
        ctrl_x_rule(),
    ]
    return rules
