# Keep the named gcloud configuration in one place so recipes never hardcode a
# GCP project ID in this public repository. Pinning the configuration also keeps
# provisioned services independent of the mutable active configuration shared by
# the host and devcontainers.
if ENV['DOTFILES_GCLOUD_CONFIGURATION'].to_s.strip.empty?
  ENV['DOTFILES_GCLOUD_CONFIGURATION'] = 'good'
end
