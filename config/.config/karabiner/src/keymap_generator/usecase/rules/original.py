from keymap_generator.domain.models.keymap import Rule
from keymap_generator.domain.models.manipulator import (
    Condition,
    From,
    FromModifiers,
    InputSource,
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

    Ctrl+\\ で ABC ↔ Google日本語入力 を直接切り替える。
    japanese_eisuu / japanese_kana キーコードを使い、
    macOS のネイティブな入力ソース切り替えパイプラインを通す。
    一方向キーのため key_up 二重発火が起きず、
    select_input_source の CJKV バグも回避できる。
    """
    from_ = From(
        key_code="backslash",
        modifiers=FromModifiers(
            mandatory=["left_control"],
        ),
    )
    rule = Rule(
        description="言語切り替え",
        manipulators=[
            Manipulator(
                from_=from_,
                to=[
                    ToItem(key_code="japanese_eisuu"),
                ],
                conditions=[
                    Condition(
                        type="input_source_if",
                        input_sources=[InputSource(input_source_id="^com\\.google\\.inputmethod\\.Japanese")],
                    ),
                ],
            ),
            Manipulator(
                from_=from_,
                to=[
                    ToItem(key_code="japanese_kana"),
                ],
                conditions=[
                    Condition(
                        type="input_source_if",
                        input_sources=[InputSource(input_source_id="^com\\.apple\\.keylayout\\.ABC$")],
                    ),
                ],
            ),
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
