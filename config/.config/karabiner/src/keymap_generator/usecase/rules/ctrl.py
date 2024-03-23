from keymap_generator.domain.models.keymap import Rule
from keymap_generator.domain.models.manipulator import (
    Condition,
    From,
    FromModifiers,
    Manipulator,
    SetVariable,
    ToItem,
)
from keymap_generator.settings import get_settings
from keymap_generator.usecase.rules.decorators import (
    add_shift_if_marked,
    clear_space,
    emacs_exclude,
)

settings = get_settings()


@emacs_exclude
@add_shift_if_marked
def move_right_rule() -> Rule:
    """カーソル右移動"""
    rule = Rule(
        description="カーソル右移動",
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
                        key_code="right_arrow",
                    )
                ],
            )
        ],
    )
    return rule


@emacs_exclude
@add_shift_if_marked
def move_left_rule() -> Rule:
    """カーソル左移動"""
    rule = Rule(
        description="カーソル左移動",
        manipulators=[
            Manipulator(
                from_=From(
                    key_code="b",
                    modifiers=FromModifiers(
                        mandatory=["left_control"],
                    ),
                ),
                to=[
                    ToItem(
                        key_code="left_arrow",
                    )
                ],
            )
        ],
    )
    return rule


@emacs_exclude
@add_shift_if_marked
def move_up_rule() -> Rule:
    """カーソル上移動"""
    rule = Rule(
        description="カーソル上移動",
        manipulators=[
            Manipulator(
                from_=From(
                    key_code="p",
                    modifiers=FromModifiers(
                        mandatory=["left_control"],
                    ),
                ),
                to=[
                    ToItem(
                        key_code="up_arrow",
                    )
                ],
            )
        ],
    )
    return rule


@emacs_exclude
@add_shift_if_marked
def move_down_rule() -> Rule:
    """カーソル下移動"""
    rule = Rule(
        description="カーソル下移動",
        manipulators=[
            Manipulator(
                from_=From(
                    key_code="n",
                    modifiers=FromModifiers(
                        mandatory=["left_control"],
                    ),
                ),
                to=[
                    ToItem(
                        key_code="down_arrow",
                    )
                ],
            )
        ],
    )
    return rule


@emacs_exclude
@add_shift_if_marked
def move_linehead_rule() -> Rule:
    """行頭へ移動"""
    rule = Rule(
        description="行頭へ移動",
        manipulators=[
            Manipulator(
                from_=From(
                    key_code="a",
                    modifiers=FromModifiers(
                        mandatory=["left_control"],
                    ),
                ),
                to=[
                    ToItem(
                        key_code="left_arrow",
                        modifiers=["left_command"],
                    )
                ],
            )
        ],
    )
    return rule


@emacs_exclude
@add_shift_if_marked
def move_lineend_rule() -> Rule:
    """行末へ移動"""
    rule = Rule(
        description="行末へ移動",
        manipulators=[
            Manipulator(
                from_=From(
                    key_code="e",
                    modifiers=FromModifiers(
                        mandatory=["left_control"],
                    ),
                ),
                to=[
                    ToItem(
                        key_code="right_arrow",
                        modifiers=["left_command"],
                    )
                ],
            )
        ],
    )
    return rule


@emacs_exclude
@add_shift_if_marked
def pagedown_rule() -> Rule:
    """ページダウン"""
    rule = Rule(
        description="ページダウン",
        manipulators=[
            Manipulator(
                from_=From(
                    key_code="v",
                    modifiers=FromModifiers(
                        mandatory=["left_control"],
                    ),
                ),
                to=[
                    ToItem(
                        key_code="page_down",
                    )
                ],
            )
        ],
    )
    return rule


@emacs_exclude
@clear_space
def delete_rule() -> Rule:
    """一文字先を削除"""
    rule = Rule(
        description="一文字先を削除",
        manipulators=[
            Manipulator(
                from_=From(
                    key_code="d",
                    modifiers=FromModifiers(
                        mandatory=["left_control"],
                    ),
                ),
                to=[
                    ToItem(
                        key_code="delete_forward",
                    )
                ],
            )
        ],
    )
    return rule


@emacs_exclude
@clear_space
def backspace_rule() -> Rule:
    """一文字前を削除"""
    rule = Rule(
        description="一文字前を削除",
        manipulators=[
            Manipulator(
                from_=From(
                    key_code="h",
                    modifiers=FromModifiers(
                        mandatory=["left_control"],
                    ),
                ),
                to=[
                    ToItem(
                        key_code="delete_or_backspace",
                    )
                ],
            )
        ],
    )
    return rule


@emacs_exclude
@clear_space
def kill_rule() -> Rule:
    """その行のカーソルより後ろを削除"""
    rule = Rule(
        description="その行のカーソルより後ろを削除",
        manipulators=[
            Manipulator(
                from_=From(
                    key_code="k",
                    modifiers=FromModifiers(
                        mandatory=["left_control"],
                    ),
                ),
                to=[
                    ToItem(
                        key_code="right_arrow",
                        modifiers=["left_shift", "left_command"],
                    ),
                    ToItem(
                        key_code="x",
                        modifiers=["left_command"],
                    ),
                ],
            )
        ],
    )
    return rule


@emacs_exclude
def cancel_rule() -> Rule:
    """キャンセル"""
    rule = Rule(
        description="キャンセル",
        manipulators=[
            Manipulator(
                from_=From(
                    key_code="g",
                    modifiers=FromModifiers(
                        mandatory=["left_control"],
                    ),
                ),
                to=[
                    ToItem(
                        key_code="escape",
                    )
                ],
            )
        ],
    )
    return rule


@emacs_exclude
@clear_space
def search_rule() -> Rule:
    """検索"""
    rule = Rule(
        description="検索",
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
                        key_code="f",
                        modifiers=["left_command"],
                    )
                ],
            )
        ],
    )
    return rule


@emacs_exclude
@clear_space
def cut_rule() -> Rule:
    """切り取り"""
    rule = Rule(
        description="切り取り",
        manipulators=[
            Manipulator(
                from_=From(
                    key_code="w",
                    modifiers=FromModifiers(
                        mandatory=["left_control"],
                    ),
                ),
                to=[
                    ToItem(
                        key_code="x",
                        modifiers=["left_command"],
                    )
                ],
            )
        ],
    )
    return rule


@emacs_exclude
@clear_space
def yank_rule() -> Rule:
    """貼り付け"""
    rule = Rule(
        description="貼り付け",
        manipulators=[
            Manipulator(
                from_=From(
                    key_code="y",
                    modifiers=FromModifiers(
                        mandatory=["left_control"],
                    ),
                ),
                to=[
                    ToItem(
                        key_code="v",
                        modifiers=["left_command"],
                    )
                ],
            )
        ],
    )
    return rule


@emacs_exclude
def set_mark_rule() -> Rule:
    """範囲選択を開始"""
    rule = Rule(
        description="範囲選択を開始",
        manipulators=[
            Manipulator(
                from_=From(
                    key_code="open_bracket",
                    modifiers=FromModifiers(
                        mandatory=["left_control"],
                    ),
                ),
                to=[
                    ToItem(
                        set_variable=SetVariable(name="C-SPC", value=1),
                    )
                ],
                conditions=[
                    Condition(
                        type="variable_unless",
                        name="C-SPC",
                        value=1,
                    )
                ],
            ),
            # 一度有効にしたら、次回はキャンセルにする
            Manipulator(
                from_=From(
                    key_code="open_bracket",
                    modifiers=FromModifiers(
                        mandatory=["left_control"],
                    ),
                ),
                to=[
                    ToItem(
                        key_code="escape",
                    )
                ],
                conditions=[
                    Condition(
                        type="variable_if",
                        name="C-SPC",
                        value=1,
                    )
                ],
            ),
        ],
    )
    return rule


def ctrl_space2ctrl_at_rule() -> Rule:
    """C-SPC -> C-@"""
    rule = Rule(
        description="C-SPC -> C-@",
        manipulators=[
            Manipulator(
                from_=From(
                    key_code="spacebar",
                    modifiers=FromModifiers(
                        mandatory=["left_control"],
                    ),
                ),
                to=[
                    ToItem(
                        key_code="open_bracket",
                        modifiers=["left_control"],
                    )
                ],
            )
        ],
    )
    return rule


def generate_ctrl_rules() -> list[Rule]:
    """ctrl系のルールを生成する

    Returns:
        list[Rule]: ctrl系のルール
    """
    rules: list[Rule] = [
        move_right_rule(),
        move_left_rule(),
        move_up_rule(),
        move_down_rule(),
        move_linehead_rule(),
        move_lineend_rule(),
        pagedown_rule(),
        delete_rule(),
        backspace_rule(),
        kill_rule(),
        cancel_rule(),
        search_rule(),
        cut_rule(),
        yank_rule(),
        set_mark_rule(),
        ctrl_space2ctrl_at_rule()
    ]
    return rules
