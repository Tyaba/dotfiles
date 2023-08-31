# Google Cloud SDK
# The next line updates PATH for the Google Cloud SDK.
if [ -f "$HOME/.bin/google-cloud-sdk/path.zsh.inc" ]; then . "$HOME/.bin/google-cloud-sdk/path.zsh.inc"; fi
# The next line enables shell command completion for gcloud.
if [ -f "$HOME/.bin/google-cloud-sdk/completion.zsh.inc" ]; then . "$HOME/.bin/google-cloud-sdk/completion.zsh.inc"; fi
export CLOUDSDK_PYTHON=python3
# Kubectl
export USE_GKE_GCLOUD_AUTH_PLUGIN=True
# Docker
export DOCKER_BUILDKIT=1
export COMPOSE_DOCKER_CLI_BUILD=1
# Travis CI
[ -f ~/.travis/travis.sh ] && source ~/.travis/travis.sh
# direnv
export EDITOR=emacs
eval "$(direnv hook zsh)"
# pre-commit
export PRE_COMMIT_COLOR=always
# ssh agent
if [ -z $SSH_AUTH_SOCK ]; then
    eval `ssh-agent -s`
    if [ -f ~/.ssh/id_ed25519 ]; then
        ssh-add ~/.ssh/id_ed25519
    fi
fi
