#!/usr/bin/env bash
# Keep a devcontainer's codex auth.json linked to the host-shared ~/.codex.
#
# In devcontainers roles/base renders config.toml / AGENTS.md into a
# container-local CODEX_HOME (~/.config/codex), because ~/.codex is a rw bind
# mount of the host's directory. auth.json -- the one file worth sharing -- is
# linked back to that mount.
#
# The link does not stay put: codex rewrites auth.json as temp-file + rename on
# token refresh, which replaces the symlink with a regular file. From then on
# the container keeps its own login, and a re-login on the host never reaches
# it. Running this only from install.sh left containers diverged for days, so
# it is also called from interactive shells (config/.zsh/lib/apps) and by the
# codex-offload subagent before `codex exec`. It must therefore be silent when
# nothing needs fixing.
set -eu

CODEX_HOME_DIR="$HOME/.config/codex"
LINK="$CODEX_HOME_DIR/auth.json"
TARGET="$HOME/.codex/auth.json"

# Only devcontainers render into ~/.config/codex. On the host ~/.codex is
# CODEX_HOME itself and auth.json there is the real file; leave it alone.
# Same probe as config/.zsh/lib/apps, since DOTFILES_ROLE is not exported.
[ -f "$CODEX_HOME_DIR/config.toml" ] || exit 0

mkdir -p "$CODEX_HOME_DIR"

relink() {
  rm -f "$LINK"
  ln -s "$TARGET" "$LINK"
}

if [ -L "$LINK" ]; then
  # Repoint if it aims somewhere stale.
  if [ "$(readlink "$LINK")" != "$TARGET" ]; then
    relink
    echo "codex-link-auth: repointed $LINK to $TARGET" >&2
  fi
elif [ -f "$LINK" ]; then
  # The link was replaced by a token refresh. Promote the container's copy only
  # when it is non-empty and newer than the shared one: promoting overwrites
  # the login of the host and every other container, so a truncated file or a
  # stale token left behind after the host logged in again must not win.
  if [ -s "$LINK" ] && { [ ! -e "$TARGET" ] || [ "$LINK" -nt "$TARGET" ]; }; then
    mv "$LINK" "$TARGET"
    ln -s "$TARGET" "$LINK"
    echo "codex-link-auth: promoted newer $LINK to $TARGET and relinked" >&2
  else
    relink
    echo "codex-link-auth: discarded stale $LINK and relinked to $TARGET" >&2
  fi
else
  # A dangling link is fine: `codex login` writes through it and the token
  # lands in the shared mount.
  ln -s "$TARGET" "$LINK"
  echo "codex-link-auth: linked $LINK to $TARGET" >&2
fi
