from pathlib import Path


def get_project_dir() -> Path:
    """プロジェクトのディレクトリを取得する

    Returns:
        Path: プロジェクトのディレクトリ
    """
    return Path(__file__).resolve().parent.parent.parent.parent
