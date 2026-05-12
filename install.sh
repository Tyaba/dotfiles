#!/bin/sh

set -ex

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
