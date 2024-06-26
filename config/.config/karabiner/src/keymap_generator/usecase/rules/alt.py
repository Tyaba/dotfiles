from keymap_generator.domain.models.keymap import Rule
from keymap_generator.domain.models.manipulator import (
    From,
    FromModifiers,
    Manipulator,
    ToItem,
)
from keymap_generator.usecase.rules.decorators import (
    add_shift_if_marked,
    clear_space,
    emacs_exclude,
)


@emacs_exclude
@add_shift_if_marked
def pageup_rule() -> Rule:
    """ページアップ"""
    rule = Rule(
        description="ページアップ",
        manipulators=[
            Manipulator(
                from_=From(
                    key_code="v",
                    modifiers=FromModifiers(
                        mandatory=["left_option"],
                    ),
                ),
                to=[
                    ToItem(
                        key_code="page_up",
                    )
                ],
            )
        ],
    )
    return rule


@emacs_exclude
@clear_space
def copy_rule() -> Rule:
    """コピー"""
    rule = Rule(
        description="コピー",
        manipulators=[
            Manipulator(
                from_=From(
                    key_code="w",
                    modifiers=FromModifiers(
                        mandatory=["left_option"],
                    ),
                ),
                to=[
                    ToItem(
                        key_code="c",
                        modifiers=["left_command"],
                    )
                ],
            )
        ],
    )
    return rule


@emacs_exclude
@add_shift_if_marked
def forward_word() -> Rule:
    """一単語先へ"""
    rule = Rule(
        description="一単語先へ",
        manipulators=[
            Manipulator(
                from_=From(
                    key_code="f",
                    modifiers=FromModifiers(
                        mandatory=["left_option"],
                    ),
                ),
                to=[
                    ToItem(
                        key_code="right_arrow",
                        modifiers=["left_option"],
                    )
                ],
            )
        ],
    )
    return rule


@emacs_exclude
@add_shift_if_marked
def backward_word() -> Rule:
    """一単語前へ"""
    rule = Rule(
        description="一単語前へ",
        manipulators=[
            Manipulator(
                from_=From(
                    key_code="b",
                    modifiers=FromModifiers(
                        mandatory=["left_option"],
                    ),
                ),
                to=[
                    ToItem(
                        key_code="left_arrow",
                        modifiers=["left_option"],
                    )
                ],
            )
        ],
    )
    return rule


def generate_alt_rules() -> list[Rule]:
    """alt系のルールを生成する

    Returns:
        list[Rule]: alt系のルール
    """
    rules: list[Rule] = [
        pageup_rule(),
        copy_rule(),
        forward_word(),
        backward_word(),
    ]
    return rules
