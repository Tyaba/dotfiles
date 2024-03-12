"""設定値を保持するモジュール"""
from datetime import datetime
from functools import cache
from pathlib import Path

from pydantic_settings import BaseSettings

from keymap_generator.domain.models.manipulator import Condition, SetVariable
from keymap_generator.utils.file import get_project_dir

DATETIME_FMT = "%Y-%m-%d_%H:%M:%S"


class Settings(BaseSettings):
    """設定値を保持するクラス"""

    name: str = "tyaba"
    keymap_maintainers: list[str] = [name]
    keymap_title: str = (
        f"Emacs key bindings ({name}) {datetime.now().strftime(DATETIME_FMT)}"
    )
    keymap_save_path: Path = (
        get_project_dir() / "assets" / "complex_modifications" / f"{name}_emacs.json"
    )
    exclude_emacs_apps: set[str] = {
        "^org\\.gnu\\.Emacs$",
        "^com\\.apple\\.Terminal$",
        "^com\\.googlecode\\.iterm2$",
        "^org\\.vim\\.",
        "^org\\.x\\.X11$",
        "^com\\.apple\\.x11$",
        "^org\\.macosforge\\.xquartz\\.X11$",
        "^org\\.macports\\.X11$",
        "^com\\.microsoft\\.VSCode$",
    }
    exclude_emacs_conditions: list[Condition] = [
        Condition(
            type="frontmost_application_unless",
            bundle_identifiers=list(exclude_emacs_apps),
        )
    ]
    set_mark: SetVariable = SetVariable(name="C-SPC", value=1)
    clear_mark: SetVariable = SetVariable(name="C-SPC", value=0)


@cache
def get_settings() -> Settings:
    """設定値を取得する

    Returns:
        BaseSettings: 設定値
    """
    return Settings()
