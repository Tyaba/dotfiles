#!/usr/bin/env python3
"""PreToolUse hook that hard-blocks destructive Bash commands.

This complements ``git-push-gate.sh`` (a soft "ask" gate for ``git push``).
Under ``claude --dangerously-skip-permissions``, the soft permission layer
is skipped entirely, so we need a fallback that blocks unrecoverable
operations by ``sys.exit(2)`` regardless of permission decisions.

Block policy:

A. ``prd`` token present in the command line and one of:
   - ``terraform <flags...> destroy ...``
   - ``terraform <flags...> apply <flags...> -auto-approve`` (auto-approve only)
   - ``gcloud <subgroup> ... delete ...``
   - ``gsutil <flags...> rm ...``
   - ``bq <flags...> rm ...`` / ``bq <flags...> delete ...``
   - ``kubectl <flags...> delete ...``

B. ``git push`` force/refspec targeting ``main`` or ``master``
   (env-independent; covers ``--dangerously-skip-permissions``).

C. Generic destructive patterns (env-independent):
   - ``rm -rf`` / ``rm -fr`` (incl. ``sudo``) when the target is one of
     ``/``, ``$HOME``, ``${HOME}``, ``~``, ``/*``, ``.``, ``..``, or empty string.
   - ``chmod 777`` / ``chmod -R 777`` / ``chmod 0777`` / ``chmod -R 0777``
     (``-R`` is optional; both wide-open recursive and single-target forms
     are blocked).
   - ``curl ... | sh|bash`` / ``wget ... | sh|bash`` pipeline execution.

D. Bypass: when ``CLAUDE_HOOK_BYPASS=1`` is set, exit 0 immediately.

E. Quoted literal handling: the command string has quoted literals
   (``"..."`` and ``'...'``) stripped before regex matching so that
   ``echo "terraform destroy"`` or ``git commit -m "fix: do not run git
   push --force main"`` are not false-flagged.
"""

import json
import os
import re
import shutil
import subprocess
import sys

# ---------------------------------------------------------------------------
# Building blocks for command-line regex.
# ---------------------------------------------------------------------------

# Boundary preceding a command token (start of line or a shell separator).
_CMD_START = r"(?:^|&&|\|\||;|\|)\s*"

# Inter-arg whitespace that allows flag tokens but not bare words. This keeps
# us from greedily matching across unrelated arguments.
_FLAGS = r"(?:\s+-\S+)*"

# Independent `prd` token (surrounded by path/word separators or string edges).
_PRD_TOKEN = re.compile(r"(?:^|[-_/\s.=:])prd(?:[-_/\s.=:]|$)")


def _re(pattern: str) -> re.Pattern[str]:
    return re.compile(pattern)


# ---------------------------------------------------------------------------
# Pattern A: prd-scoped infra mutations.
# ---------------------------------------------------------------------------

_PRD_PATTERNS: list[tuple[re.Pattern[str], str]] = [
    (
        _re(_CMD_START + r"terraform" + _FLAGS + r"\s+destroy\b"),
        "terraform destroy targeting prd",
    ),
    (
        # apply ... -auto-approve (order: apply, then flags including -auto-approve)
        _re(
            _CMD_START
            + r"terraform"
            + _FLAGS
            + r"\s+apply\b"
            + r"(?:\s+\S+)*?\s+-auto-approve\b"
        ),
        "terraform apply -auto-approve targeting prd",
    ),
    (
        # gcloud <subgroup> ... delete ...
        _re(_CMD_START + r"gcloud\s+\S+(?:\s+\S+)*?\s+delete\b"),
        "gcloud delete targeting prd",
    ),
    (
        _re(_CMD_START + r"gsutil" + _FLAGS + r"\s+rm\b"),
        "gsutil rm targeting prd",
    ),
    (
        _re(_CMD_START + r"bq" + _FLAGS + r"\s+rm\b"),
        "bq rm targeting prd",
    ),
    (
        _re(_CMD_START + r"bq" + _FLAGS + r"\s+delete\b"),
        "bq delete targeting prd",
    ),
    (
        _re(_CMD_START + r"kubectl" + _FLAGS + r"\s+delete\b"),
        "kubectl delete targeting prd",
    ),
]

# ---------------------------------------------------------------------------
# Pattern C: generic destructive Bash patterns.
# ---------------------------------------------------------------------------

# rm -rf with a sensitive target.
# Accept any flag-cluster containing both 'r' (case-insensitive) and 'f', plus
# the canonical short forms -rf / -fr / -Rf / -fR.
_RM_RF = re.compile(
    _CMD_START
    + r"(?:sudo\s+)?rm\s+"
    + r"(?:"
    + r"-[a-zA-Z]*r[a-zA-Z]*f[a-zA-Z]*"
    + r"|-[a-zA-Z]*R[a-zA-Z]*f[a-zA-Z]*"
    + r"|-[a-zA-Z]*f[a-zA-Z]*r[a-zA-Z]*"
    + r"|-[a-zA-Z]*f[a-zA-Z]*R[a-zA-Z]*"
    + r")"
    + r"\s+(?P<target>\S+)"
)

# Sensitive rm targets (resolved after quoted-literal stripping).
_SENSITIVE_RM_TARGETS = {
    "/",
    "/*",
    "~",
    "~/",
    "~/*",
    "$HOME",
    "${HOME}",
    "$HOME/*",
    "${HOME}/*",
    ".",
    "./",
    "./*",
    "..",
    "../",
    "../*",
    "",
}

_CHMOD_WIDE = re.compile(
    _CMD_START + r"(?:sudo\s+)?chmod\s+(?:-R\s+)?0?777\b"
)

_CURL_PIPE = re.compile(
    _CMD_START
    + r"(?:curl|wget)\s+[^|;&]+\|\s*(?:sudo\s+)?(?:sh|bash)\b"
)


# ---------------------------------------------------------------------------
# Quoted literal stripping.
# ---------------------------------------------------------------------------

def _strip_quoted(cmd: str) -> str:
    """Remove text inside quoted literals, leaving the quotes themselves.

    This is a deliberately simple state machine that handles the common case
    of ``"..."`` and ``'...'`` literals. It does not fully model shell
    escaping or nested quotes — false negatives there are acceptable because
    the user-facing failure mode (false positive on a benign quoted string)
    is much worse than a missed exotic edge case.
    """
    out: list[str] = []
    quote: str | None = None
    i = 0
    n = len(cmd)
    while i < n:
        ch = cmd[i]
        if quote is None:
            if ch in ("'", '"'):
                quote = ch
                out.append(ch)
            else:
                out.append(ch)
            i += 1
        else:
            if ch == "\\" and i + 1 < n and quote == '"':
                # Skip escape inside double quotes.
                i += 2
                continue
            if ch == quote:
                out.append(ch)
                quote = None
            # else: drop content inside the quoted literal
            i += 1
    return "".join(out)


# ---------------------------------------------------------------------------
# git push handling.
# ---------------------------------------------------------------------------

_FORCE_FLAG = re.compile(r"(?:^|\s)(?:--force(?:-with-lease)?|--mirror)(?:\s|=|$)")
# Match short -f either standalone or combined with other short flags
# (e.g. ``-fu``, ``-vf``, ``-uf``). For ``git push`` the only short flag whose
# letter is ``f`` is ``--force``, so treating any ``-...f...`` cluster as force
# is the correct behavior here.
_F_SHORT = re.compile(r"(?:^|\s)-[a-zA-Z]*f[a-zA-Z]*(?:\s|$)")
_PROTECTED_BRANCHES = {"main", "master"}


def _check_git_push_force_protected(cmd: str) -> str | None:
    """Return a block reason if `cmd` is a force push targeting main/master."""
    # Look for a git push subcommand anywhere in the line.
    m = re.search(
        r"(?:^|&&|\|\||;|\|)\s*git\s+(?:-[A-Za-z\-]+\s+)*push\b(?P<rest>.*)$",
        cmd,
    )
    if not m:
        return None
    rest = m.group("rest")

    has_force_flag = bool(_FORCE_FLAG.search(rest) or _F_SHORT.search(rest))

    # Tokenize positional args (strip flags). Mirror git-push-gate.sh logic.
    tokens = rest.split()
    positionals: list[str] = []
    skip_next = False
    for tok in tokens:
        if skip_next:
            skip_next = False
            continue
        if tok in (";", "&&", "||", "|", ">", ">>", "&"):
            break
        if tok in ("-o", "--push-option"):
            skip_next = True
            continue
        if tok.startswith("-"):
            continue
        positionals.append(tok)

    refspecs: list[str] = []
    if len(positionals) <= 1:
        cur = _current_git_branch()
        if cur:
            refspecs.append(cur)
    else:
        refspecs.extend(positionals[1:])

    has_plus_refspec = any(rs.startswith("+") for rs in refspecs)

    if not (has_force_flag or has_plus_refspec):
        return None

    for rs in refspecs:
        if not rs:
            continue
        dst = rs.split(":", 1)[1] if ":" in rs else rs
        dst = dst.lstrip("+")
        if dst.startswith("refs/heads/"):
            dst = dst[len("refs/heads/") :]
        if dst in _PROTECTED_BRANCHES:
            return f"force git push targets protected branch '{dst}'"
    return None


def _current_git_branch() -> str:
    git = shutil.which("git")
    if git is None:
        return ""

    try:
        return subprocess.check_output(
            [git, "rev-parse", "--abbrev-ref", "HEAD"],
            stderr=subprocess.DEVNULL,
            text=True,
        ).strip()
    except (subprocess.CalledProcessError, OSError):
        return ""


# ---------------------------------------------------------------------------
# Main entry point.
# ---------------------------------------------------------------------------

def _block(reason: str) -> None:
    sys.stderr.write(f"[pre-tool-block-destructive] BLOCK: {reason}\n")
    sys.exit(2)


def _load_command() -> str | None:
    try:
        payload = json.load(sys.stdin)
    except (ValueError, OSError):
        # If we cannot parse the payload, be permissive (do not block).
        return None

    tool_input = payload.get("tool_input") or {}
    cmd_raw = tool_input.get("command")
    if not isinstance(cmd_raw, str) or not cmd_raw.strip():
        return None

    return _strip_quoted(cmd_raw)


def _block_prd_mutations(cmd: str) -> None:
    if _PRD_TOKEN.search(cmd):
        for pattern, reason in _PRD_PATTERNS:
            if pattern.search(cmd):
                _block(reason)


def _block_generic_destructive(cmd: str) -> None:
    for m in _RM_RF.finditer(cmd):
        target = m.group("target")
        if target in _SENSITIVE_RM_TARGETS:
            _block(f"rm -rf against sensitive target '{target or '<empty>'}'")

    if _CHMOD_WIDE.search(cmd):
        _block("chmod 777 / chmod -R 777 (or 0777) detected: overly permissive")

    if _CURL_PIPE.search(cmd):
        _block("piping curl/wget output into sh/bash detected")


def main() -> None:
    if os.environ.get("CLAUDE_HOOK_BYPASS") == "1":
        sys.exit(0)

    cmd = _load_command()
    if cmd is None:
        sys.exit(0)

    _block_prd_mutations(cmd)

    # Pattern B: force push to protected branches.
    reason = _check_git_push_force_protected(cmd)
    if reason:
        _block(reason)

    _block_generic_destructive(cmd)

    sys.exit(0)


if __name__ == "__main__":
    main()
