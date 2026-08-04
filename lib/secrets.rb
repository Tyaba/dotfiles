# Resolves API keys for the coding-agent templates (~/.mcp.json,
# ~/.codex/config.toml) and exports them into ENV so the ERBs can embed them.
#
# Resolution order per key, first hit wins:
#
#   1. an already-exported ENV var       escape hatch / CI override
#   2. config/coding_agents/private/     git-ignored, host only, offline
#   3. GCP Secret Manager                source of truth, host + devcontainer
#
# Tier 3 is what makes devcontainers work. post-create.sh clones this repo
# fresh from GitHub, so the git-ignored private/ directory never exists inside
# the container -- but ~/.config/gcloud is bind-mounted, so the same gcloud
# lookup succeeds there.
#
# Nothing here is fatal. A key that stays unresolved renders as "no credential"
# and the MCP server falls back to unauthenticated (rate-limited) access.
#
# mruby note: mitamae is mruby-based. File.readlines and Integer#zero? do not
# exist there; File.foreach and `== 0` do.

root_dir = File.expand_path('../..', __FILE__)
include_recipe File.join(root_dir, 'lib/gcloud.rb')

# Secret Manager secret name per ENV var. Extend this map to add more keys.
gcp_secrets = {
  'CONTEXT7_API_KEY' => 'context7-api-key',
}

# --- tier 2: config/coding_agents/private/secrets.env ---------------------
#
# One KEY=value per line. `export ` prefixes, surrounding quotes, blank lines
# and # comments are tolerated.
private_secrets = File.join(root_dir, 'config/coding_agents/private/secrets.env')
if File.exist?(private_secrets)
  File.foreach(private_secrets) do |line|
    line = line.strip
    next if line.empty? || line.start_with?('#')

    key, separator, value = line.partition('=')
    next if separator.empty?

    key = key.sub(/\Aexport\s+/, '').strip
    next if key.empty? || !ENV[key].to_s.empty?

    ENV[key] = value.strip.gsub(/\A(['"])(.*)\1\z/m, '\2')
  end
end

# --- tier 3: GCP Secret Manager -------------------------------------------
pending = gcp_secrets.reject { |env_key, _| !ENV[env_key].to_s.empty? }

unless pending.empty?
  gcloud_configuration = ENV['DOTFILES_GCLOUD_CONFIGURATION'].to_s.strip

  shell_quote = lambda do |value|
    "'" + value.to_s.gsub("'", "'\"'\"'") + "'"
  end
  gcloud_config_env = "CLOUDSDK_ACTIVE_CONFIG_NAME=#{shell_quote.call(gcloud_configuration)} "

  # Read the project id from a named gcloud configuration rather than
  # hardcoding it: this repo is public, and ~/.config/gcloud is bind-mounted into
  # devcontainers. Pinning the configuration keeps both the project and account
  # independent of the mutable active configuration shared with containers.
  project = ENV['DOTFILES_GCP_PROJECT'].to_s.strip
  if project.empty?
    result = run_command(
      "#{gcloud_config_env}gcloud config configurations describe #{shell_quote.call(gcloud_configuration)} " \
      "--format='value(properties.core.project)' 2>/dev/null",
      error: false
    )
    project = result.exit_status == 0 ? result.stdout.strip : ''
  end

  if project.empty?
    MItamae.logger.warn(
      "secrets: no GCP project resolved (gcloud missing, or no '#{gcloud_configuration}' " \
      "configuration); skipping Secret Manager lookup"
    )
  else
    pending.each do |env_key, secret_name|
      result = run_command(
        "#{gcloud_config_env}gcloud secrets versions access latest " \
        "--secret=#{shell_quote.call(secret_name)} --project=#{shell_quote.call(project)} 2>/dev/null",
        error: false
      )

      if result.exit_status == 0 && !result.stdout.strip.empty?
        ENV[env_key] = result.stdout.strip
        MItamae.logger.info("secrets: #{env_key} <- Secret Manager (#{secret_name})")
      else
        # Loud on purpose: the templates below are about to overwrite a
        # possibly-working config with a credential-less one.
        MItamae.logger.warn(
          "secrets: #{env_key} unresolved (gcloud exit=#{result.exit_status}); " \
          "rendering without it -- the server falls back to unauthenticated access"
        )
      end
    end
  end
end
