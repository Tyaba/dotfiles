#!/bin/sh

set -ex

# Resolve relative paths (bin/setup, bin/mitamae, lib/recipe.rb) against this
# script's directory rather than the caller's cwd. Without this, calling
# `$DOTFILES_DIR/install.sh` from elsewhere (e.g. a devcontainer
# postCreateCommand running from /workspaces/<project>) fails with
# `bin/setup: not found`.
cd "$(dirname "$0")"

bin/setup

# DOTFILES_ROLE=devcontainer skips sudo: deploys only user-level
# dotfiles + codex CLI (no apt / no system packages).
if [ "${DOTFILES_ROLE:-}" = "devcontainer" ]; then
  bin/mitamae local $@ lib/recipe.rb
  exit
fi

case "$(uname)" in
  "Darwin")  bin/mitamae local $@ lib/recipe.rb ;;
  *) sudo -E bin/mitamae local $@ lib/recipe.rb ;;
esac
