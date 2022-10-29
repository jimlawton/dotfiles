# Fig pre block. Keep at the top of this file.
[[ -f "$HOME/.fig/shell/profile.pre.bash" ]] && builtin source "$HOME/.fig/shell/profile.pre.bash"
#############################################################
# Generic configuration that applies to all shells
#############################################################

# Load user-specific personalisation.
source ~/dotfiles/personalisation

# Load paths and environment variables
source ~/dotfiles/shellvars
source ~/dotfiles/shellfunctions
source ~/dotfiles/shellpaths
source ~/dotfiles/shellaliases
source ~/dotfiles/shellactivities

export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init --path)"
if which pyenv-virtualenv-init > /dev/null; then eval "$(pyenv virtualenv-init -)"; fi

# goenv setup
eval "$(goenv init -)"

export PATH="$GOROOT/bin:$PATH"
export PATH="$PATH:$GOPATH/bin"

# Fig post block. Keep at the bottom of this file.
[[ -f "$HOME/.fig/shell/profile.post.bash" ]] && builtin source "$HOME/.fig/shell/profile.post.bash"
