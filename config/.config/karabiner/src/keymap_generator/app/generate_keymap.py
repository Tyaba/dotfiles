"""emacsライクなkarabiner elementsのキーマップを生成する
poetry run python -m keymap_generator.app.generate_keymap \
    --save-path ~/.config/karabiner/assets/complex_modifications/tyaba_emacs.json
"""
from argparse import ArgumentParser, Namespace
from pathlib import Path

from keymap_generator.app.injector import inject_keymap_generator
from keymap_generator.settings import get_settings
from keymap_generator.usecase.generate_emacs_keymap import GenerateEmacsKeymapUsecase

settings = get_settings()


def main(args: Namespace) -> None:
    """emacsライクなキーマップを生成して保存する

    Args:
        args (Namespace): コマンドライン引数
    """
    generate_keymap(save_path=args.save_path)
    return None


def generate_keymap(save_path: Path) -> None:
    """emacsライクなキーマップを生成して保存する

    Args:
        save_path (Path): jsonの保存path
    """
    generator = inject_keymap_generator()
    usecase = GenerateEmacsKeymapUsecase(keymap_generator=generator)
    usecase.generate(save_path=save_path)
    return None


if __name__ == "__main__":
    parser = ArgumentParser()
    parser.add_argument(
        "--save-path",
        type=Path,
        help="karabiner elementsのjsonの保存path",
        required=False,
        default=settings.keymap_save_path,
    )
    commandline_args = parser.parse_args()
    main(args=commandline_args)
