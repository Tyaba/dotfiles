from functools import wraps

from keymap_generator.domain.models.keymap import Rule
from keymap_generator.domain.models.manipulator import Condition, Manipulator, ToItem
from keymap_generator.settings import get_settings

settings = get_settings()


def emacs_exclude(func):  # type: ignore
    """emacsキーバインドがネイティブサポートされるappsをexcludeする"""

    @wraps(func)
    def wrapper(*args, **kwargs) -> Rule:  # type: ignore
        old_rule: Rule = func(*args, **kwargs)
        # 追加処理
        manipulators = []
        for _manipulator in old_rule.manipulators:
            conditions = (
                _manipulator.conditions + settings.exclude_emacs_conditions
                if _manipulator.conditions is not None
                else settings.exclude_emacs_conditions
            )
            manipulator = _manipulator.model_copy(update={"conditions": conditions})
            manipulators.append(manipulator)
        rule: Rule = old_rule.model_copy(update={"manipulators": manipulators})
        return rule

    return wrapper


def clear_space(func):  # type: ignore
    """マーク状態を解除する"""

    @wraps(func)
    def wrapper(*args, **kwargs) -> Rule:  # type: ignore
        old_rule: Rule = func(*args, **kwargs)
        # 追加処理
        to_item = ToItem(set_variable=settings.clear_mark)
        manipulators: list[Manipulator] = []
        for _manipulator in old_rule.manipulators:
            to_items = (
                _manipulator.to + [to_item]
                if _manipulator.to is not None
                else [to_item]
            )
            manipulator = _manipulator.model_copy(update={"to": to_items})
            manipulators.append(manipulator)
        rule: Rule = old_rule.model_copy(update={"manipulators": manipulators})
        return rule

    return wrapper


def add_shift_if_marked(func):  # type: ignore
    """マーク状態の場合にshiftを追加するようなmanipulatorを複製する"""

    @wraps(func)
    def wrapper(*args, **kwargs) -> Rule:  # type: ignore
        old_rule: Rule = func(*args, **kwargs)
        to_item = ToItem(
            modifiers=["left_shift"],
        )
        condition = Condition(
            type="variable_if",
            name=settings.set_mark.name,
            value=1,
        )
        # 追加処理
        manipulators = []
        for _manipulator in old_rule.manipulators:
            to_items = (
                _manipulator.to + [to_item]
                if _manipulator.to is not None
                else [to_item]
            )
            conditions = (
                _manipulator.conditions + [condition]
                if _manipulator.conditions is not None
                else [condition]
            )
            manipulator: Manipulator = _manipulator.model_copy(
                update={"to": to_items, "conditions": conditions}
            )
            # マーク状態の場合のmanipulatorを追加
            manipulators.append(manipulator)
            manipulators.append(_manipulator)
        new_rule = old_rule.model_copy(update={"manipulators": manipulators})
        return new_rule

    return wrapper


def only_when_ctrl_x(func):  # type: ignore
    """ctrl-x prefix時のみ発動する処理の記述"""

    @wraps(func)
    def wrapper(*args, **kwargs) -> Rule:  # type: ignore
        rule = func(*args, **kwargs)
        manipulators: list[Manipulator] = []
        condition = Condition(
            type="variable_if",
            name="C-x",
            value=1,
        )
        for _manipulator in rule.manipulators:
            conditions = (
                _manipulator.conditions + [condition]
                if _manipulator.conditions is not None
                else [condition]
            )
            manipulator: Manipulator = _manipulator.model_copy(
                update={
                    "conditions": conditions,
                }
            )
            manipulators.append(manipulator)
        return rule

    return wrapper
