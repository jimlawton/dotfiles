# Fig pre block. Keep at the top of this file.
export PATH="${PATH}:${HOME}/.local/bin"
eval "$(fig init bash pre)"

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

# Fig post block. Keep at the bottom of this file.
eval "$(fig init bash post)"

