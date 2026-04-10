from keymap_generator.domain.models.keymap import Rule
from keymap_generator.domain.models.manipulator import (
    From,
    FromModifiers,
    Manipulator,
    ToItem,
)
from keymap_generator.usecase.rules.decorators import clear_space


@clear_space
def next_window_rule() -> Rule:
    """同一アプリケーションの次のウィンドウに移動するルールを生成する"""
    rule = Rule(
        description="同一アプリケーションの次のウィンドウに移動",
        manipulators=[
            Manipulator(
                from_=From(
                    key_code="tab",
                    modifiers=FromModifiers(
                        mandatory=["option"],
                    ),
                ),
                to=[
                    ToItem(
                        key_code="2",
                        modifiers=["left_command", "left_shift"],
                    )
                ],
                conditions=None,  # いつでも有効
            )
        ],
    )
    return rule


def change_language_rule() -> Rule:
    """言語切り替えのルールを生成する

    Ctrl+\\ を F18 に変換し、macOS 側で F18 を入力ソース切り替えに割り当てる。
    Ctrl+Space は tmux prefix と競合するため使用しない。
    """
    rule = Rule(
        description="言語切り替え",
        manipulators=[
            Manipulator(
                from_=From(
                    key_code="backslash",
                    modifiers=FromModifiers(
                        mandatory=["left_control"],
                    ),
                ),
                to=[
                    ToItem(
                        key_code="f18",
                    ),
                ],
                conditions=None,  # いつでも有効
            )
        ],
    )
    return rule


def generate_original_rules() -> list[Rule]:
    """emacsではないオリジナルのルールを生成する

    Returns:
        list[Rule]: 独自ルール
    """
    rules: list[Rule] = [next_window_rule(), change_language_rule()]
    return rules
