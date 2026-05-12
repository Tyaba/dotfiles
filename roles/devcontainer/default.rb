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
