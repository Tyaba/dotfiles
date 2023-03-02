# Google Cloud SDK
# The next line updates PATH for the Google Cloud SDK.
if [ -f "$HOME/google-cloud-sdk/path.zsh.inc" ]; then . "$HOME/google-cloud-sdk/path.zsh.inc"; fi
# The next line enables shell command completion for gcloud.
if [ -f "$HOME/google-cloud-sdk/completion.zsh.inc" ]; then . "$HOME/google-cloud-sdk/completion.zsh.inc"; fi
export CLOUDSDK_PYTHON=python3
# Kubectl
export USE_GKE_GCLOUD_AUTH_PLUGIN=True

# Docker
export DOCKER_BUILDKIT=1
export COMPOSE_DOCKER_CLI_BUILD=1

# direnv
export EDITOR=nvim
eval "$(direnv hook zsh)"

# hdf5
if uname | grep "Darwin"; then
  export HDF5_DIR="$(brew --prefix hdf5)"
fi

# Travis CI
[ -f ~/.travis/travis.sh ] && source ~/.travis/travis.sh
