from keymap_generator.domain.models.keymap import Keymap
from keymap_generator.domain.services.keymap_generator import (
    GenerateInput,
    GenerateOutput,
    KeymapGeneratorInterface,
)


class KeymapGenerator(KeymapGeneratorInterface):
    def __init__(self) -> None:
        return None

    def generate(self, generate_input: GenerateInput) -> GenerateOutput:
        """Karabiner-Elementsのkeymapのjsonを生成する

        Returns:
            Keymap: Karabiner-Elementsのkeymapのjson
        """
        keymap = Keymap(
            title=generate_input.title,
            maintainers=generate_input.maintainers,
            rules=generate_input.rules,
        )
        generate_output = GenerateOutput(keymap=keymap)
        return generate_output
