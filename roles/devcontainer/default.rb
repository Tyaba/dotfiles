# Lightweight role for dev containers (Ubuntu/Debian base image).
#
# Assumptions:
# - devcontainer features already installed git / gh / gcloud / mise / claude
# - project .mise.toml installs language runtimes (python/uv, node/pnpm)
# - install.sh runs as the workspace user (no sudo) when DOTFILES_ROLE=devcontainer
#
# Deploys user-level dotfiles (coding agents, MCP, gitconfig, zsh) and the
# codex CLI which claude's MCP config depends on. Heavy cookbooks
# (emacs / docker / ghostty / redis / brew / GUI apps) and macOS-only setup
# are intentionally excluded.

# mise shims must be on PATH so npm/uv calls below find mise-managed tools.
# (Devcontainer features install mise but PATH propagation depends on the
# shell context; ensure it explicitly here.)
mise_shims = "#{ENV['HOME']}/.local/share/mise/shims"
unless ENV['PATH'].include?(mise_shims)
  MItamae.logger.info("Prepending #{mise_shims} to PATH for this run")
  ENV['PATH'] = "#{mise_shims}:#{ENV['PATH']}"
end

# Persist ~/.claude.json across container rebuilds.
#
# devcontainer.json mounts ~/.claude/ as a named volume, but ~/.claude.json
# is a regular file outside that mount. On rebuild, the file is recreated
# empty and Claude Code re-prompts for onboarding even though credentials
# (in ~/.claude/.credentials.json) are preserved.
#
# Symlink ~/.claude.json into the persistent volume so onboarding flags,
# mcpServers config, and oauthAccount survive container recreation.
claude_link   = "#{ENV['HOME']}/.claude.json"
claude_target = "#{ENV['HOME']}/.claude/.claude.json"

execute 'persist ~/.claude.json into ~/.claude/ volume' do
  command <<~SH
    set -eu
    LINK="#{claude_link}"
    TARGET="#{claude_target}"

    # Case 1: $LINK is a regular file (not yet symlinked). Migrate its
    # contents into the volume, archiving any volume-side file conflict.
    if [ -f "$LINK" ] && [ ! -L "$LINK" ]; then
      if [ -e "$TARGET" ] && [ ! -L "$TARGET" ]; then
        # Volume already has its own .claude.json — prefer it, archive host copy.
        # Timestamp the backup so repeated rebuilds don't clobber prior archives.
        mv "$LINK" "$LINK.pre-link.bak.$(date +%s)"
      else
        mv "$LINK" "$TARGET"
      fi
    fi

    # Case 2: $TARGET still does not exist (fresh volume). Touch an empty file.
    [ -e "$TARGET" ] || : > "$TARGET"

    # Case 3: Ensure $LINK is a symlink pointing to $TARGET.
    if [ -L "$LINK" ]; then
      current="$(readlink "$LINK")"
      if [ "$current" != "$TARGET" ]; then
        rm "$LINK"
        ln -s "$TARGET" "$LINK"
      fi
    elif [ ! -e "$LINK" ]; then
      ln -s "$TARGET" "$LINK"
    fi
  SH
  user node[:user] if node[:user]
end

include_role 'base'

# Codex CLI is referenced by ~/.mcp.json (codex MCP server). Without it,
# claude logs MCP startup errors on every launch.
#
# Install via mise's npm backend instead of `npm install -g`: the devcontainer
# role runs without sudo, so the system-wide npm prefix (/usr/lib/node_modules)
# is not writable. mise installs into ~/.local/share/mise/installs and
# creates a shim under ~/.local/share/mise/shims (already on PATH).
execute 'install codex cli (mise npm backend)' do
  command "mise use -g 'npm:@openai/codex@latest'"
  not_if 'command -v codex'
end

# Install Claude Code CLI via mise instead of relying on the devcontainer feature.
#
# The devcontainer feature installs as root into /usr/lib/node_modules, so the
# vscode user cannot self-update. mise installs under ~/.local/share/mise so
# `claude` updates land in a vscode-writable path.
execute 'install claude code cli (mise npm backend)' do
  command "mise use -g 'npm:@anthropic-ai/claude-code@latest'"
  not_if 'mise which claude >/dev/null 2>&1'
end
