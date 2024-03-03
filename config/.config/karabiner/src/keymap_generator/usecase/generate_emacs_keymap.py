"""emacsライクなキーマップを生成するユースケース"""

from pathlib import Path

from keymap_generator.domain.models.keymap import Keymap, Rule
from keymap_generator.domain.services.keymap_generator import (
    GenerateInput,
    KeymapGeneratorInterface,
)
from keymap_generator.settings import get_settings
from keymap_generator.usecase.rules.alt import generate_alt_rules
from keymap_generator.usecase.rules.ctrl import generate_ctrl_rules
from keymap_generator.usecase.rules.ctrl_x import generate_ctrl_x_rules
from keymap_generator.usecase.rules.original import generate_original_rules

settings = get_settings()


class GenerateEmacsKeymapUsecase:
    """emacsライクなキーマップを生成するユースケース"""

    def __init__(self, keymap_generator: KeymapGeneratorInterface) -> None:
        self.keymap_generator = keymap_generator

    def _generate(
        self,
        title: str = settings.keymap_title,
        maintainers: list[str] | None = None,
    ) -> Keymap:
        rules: list[Rule] = generate_emacs_rules()
        keymap_generator_input = GenerateInput(
            title=title,
            maintainers=maintainers
            if maintainers is not None
            else settings.keymap_maintainers,
            rules=rules,
        )
        keymap_output = self.keymap_generator.generate(keymap_generator_input)
        return keymap_output.keymap

    def generate(self, save_path: Path = settings.keymap_save_path) -> None:
        """emacsライクなキーマップを生成する

        Args:
            save_path (Path): セーブ先json path. Defaults to settings.keymap_save_path.
        """
        key_map = self._generate()
        key_map_json = key_map.dump_with_rename()
        with open(save_path, "w", encoding="utf-8") as f:
            f.write(key_map_json)


def generate_emacs_rules() -> list[Rule]:
    """emacsライクなキーマップを生成する

    Returns:
        list[Rule]: emacsライクなキーマップのルール
    """
    original_rules: list[Rule] = generate_original_rules()
    ctrl_rules: list[Rule] = generate_ctrl_rules()
    ctrl_x_rules: list[Rule] = generate_ctrl_x_rules()
    alt_rules: list[Rule] = generate_alt_rules()
    rules: list[Rule] = ctrl_rules + ctrl_x_rules + alt_rules + original_rules
    return rules
