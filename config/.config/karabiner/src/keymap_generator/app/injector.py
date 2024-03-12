from keymap_generator.domain.services.keymap_generator import KeymapGeneratorInterface
from keymap_generator.infra.services.keymap_generator import KeymapGenerator


def inject_keymap_generator() -> KeymapGeneratorInterface:
    """keymap generatorの依存性注入

    Returns:
        KeymapGeneratorInterface: keymap generator instance
    """
    return KeymapGenerator()
