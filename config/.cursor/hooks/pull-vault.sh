#!/bin/bash
# Pull latest vault changes at session end

cd ~/ghq/github.com/Tyaba/vault || exit 1
git pull --rebase origin main
