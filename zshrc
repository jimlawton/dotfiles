# Interactive shell configuration.

##############################################################################
# ZShell History Configuration
##############################################################################
export HISTFILE=~/.zsh_history   # Where to save history to disk
export HISTFILESIZE=1000000000
export HISTSIZE=1000000000       # How many lines of history to keep in memory
export SAVEHIST=1000000000       # Number of history entries to save to disk
export HISTTIMEFORMAT="[%F %T] "
export HIST_STAMPS="+%Y-%m-%d %H:%M:%S"
export HISTDUP=erase             # Erase duplicates in the history file
#export DISABLE_VENV_CD=1         # virtualenvwrapper

setopt APPEND_HISTORY            # Append history to the history file (no overwriting)
#setopt SHARE_HISTORY             # Share history between all sessions.
setopt INC_APPEND_HISTORY        # Write to the history file immediately, not when the shell exits.
setopt EXTENDED_HISTORY          # Write the history file in the ":start:elapsed;command" format.
setopt HIST_EXPIRE_DUPS_FIRST    # Expire duplicate entries first when trimming history.
setopt HIST_IGNORE_DUPS          # Don't record an entry that was just recorded again.
setopt HIST_REDUCE_BLANKS        # Remove superfluous blanks before recording entry.
setopt HIST_FIND_NO_DUPS         # Do not display a line previously found.
setopt BANG_HIST                 # Treat the '!' character specially during expansion.

#setopt HIST_IGNORE_ALL_DUPS      # Delete old recorded entry if new entry is a duplicate.
setopt HIST_IGNORE_SPACE         # Don't record an entry starting with a space.
#setopt HIST_SAVE_NO_DUPS         # Don't write duplicate entries in the history file.
#setopt HIST_VERIFY               # Don't execute immediately upon history expansion.
#setopt HIST_BEEP                 # Beep when accessing nonexistent history.

setopt AUTO_CD                   # Automatically cd to a path if specified as a command.

setopt CORRECT                   # Correction.
#setopt CORRECT_ALL               # Correction.
setopt NO_CASE_GLOB              # Case-insensitive globbing.

# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

##############################################################################
# Input key bindings.
##############################################################################
#set bell-style none
#set match-hidden-files off
bindkey '\e[A' history-search-backward
bindkey '\e[B' history-search-forward
bindkey '\e[C' forward-char
bindkey '\e[D' backward-char
bindkey '\e[3;5~' backward-kill-word
bindkey '^?' backward-kill-word
bindkey '\e(' kill-word
bindkey '\e[1;5D' backward-word
bindkey '\e[1;5C' forward-word

##############################################################################
# oh-my-zsh setup
##############################################################################

# Path to your oh-my-zsh configuration.
export ZSH=$HOME/dotfiles/oh-my-zsh

# Set name of the theme to load.
# Look in $ZSH/themes/
# Optionally, if you set this to "random", it'll load a random theme each
# time that oh-my-zsh is loaded.

#export ZSH_THEME="gozilla"
#export ZSH_THEME="fino"
#export ZSH_THEME="takashiyoshida"
#export ZSH_THEME="random"
#export ZSH_THEME="jnrowe"
#export ZSH_THEME="agnoster"

# powerlevel10k has to be set separately. See:
# https://github.com/romkatv/powerlevel10k/blob/master/README.md#cannot-make-powerlevel10k-work-with-my-plugin-manager
#export ZSH_THEME="powerline10k"

# Set to this to use case-sensitive completion
export CASE_SENSITIVE="true"

# Comment this out to disable weekly auto-update checks
# export DISABLE_AUTO_UPDATE="true"

# Uncomment following line if you want to disable colors in ls
# export DISABLE_LS_COLORS="true"

# Uncomment following line if you want to disable autosetting terminal title.
# export DISABLE_AUTO_TITLE="true"

# Which plugins would you like to load? (plugins can be found in ~/.dotfiles/oh-my-zsh/plugins/*)
plugins=(
  aws
  battery
  brew
  colorize
  dirpersist
  docker
  fast-syntax-highlighting
  git
  gitignore
  golang
  iterm2
  macos
  pip
  # pipenv
  pyenv
  pylint
  python
  ripgrep
  # ssh-agent
  sublime
  sublime-merge
  # sudo
  terraform
  textmate
  virtualenv
  # virtualenvwrapper
)

source $HOME/dotfiles/powerlevel10k/powerlevel10k.zsh-theme
source $HOME/dotfiles/zsh-autosuggestions/zsh-autosuggestions.zsh
source $ZSH/oh-my-zsh.sh

# Load rbenv ruby version selector
# https://github.com/rbenv/rbenv#homebrew-on-macos
#eval "$(rbenv init -)"

##############################################################################
# pyenv setup.
##############################################################################
if [ -d "$HOME/.pyenv" ]; then
    # See if there is a user-install...
    if ! command -v pyenv 1>/dev/null 2>&1; then
        export PYENV_ROOT="$HOME/.pyenv"
        export PATH="$PYENV_ROOT/bin:$PATH"
    fi
    if command -v pyenv 1>/dev/null 2>&1; then
        eval "$(pyenv init --path)"
        eval "$(pyenv virtualenv-init -)"
    fi
fi
eval "$(pyenv init - --no-rehash zsh)"

test -e "${HOME}/.iterm2_shell_integration.zsh" && source "${HOME}/.iterm2_shell_integration.zsh"
# For proper imgcat use, comment out the following line:
# unalias imgcat
# see https://github.com/eddieantonio/imgcat

# To customize prompt, run `p10k configure` or edit ~/dotfiles/p10k.zsh.
[[ ! -f ~/dotfiles/p10k.zsh ]] || source ~/dotfiles/p10k.zsh

# Quieten startup errors.
#typeset -g POWERLEVEL9K_INSTANT_PROMPT=quiet

##############################################################################
# zsh completion setup.
##############################################################################

GIT_EXTRAS=/usr/local/opt/git-extras/share/git-extras/git-extras-completion.zsh
[[ ! -f $GIT_EXTRAS ]] || source $GIT_EXTRAS

# Make target completion.
zstyle ':completion:*:*:make:*' tag-order 'targets'

# Partial completion suggestions.
# https://scriptingosx.com/2019/07/moving-to-zsh-part-5-completions/
zstyle ':completion:*' list-suffixes zstyle ':completion:*' expand prefix suffix 

# The following lines were added by compinstall

zstyle ':completion:*' completer _expand _complete _ignored _approximate
zstyle :compinstall filename $HOME/.zshrc

autoload -Uz compinit
compinit
# End of lines added by compinstall

# >>> conda initialize >>>
# !! Contents within this block are managed by 'conda init' !!
__conda_setup="$(\"${HOME}/opt/miniconda3/bin/conda\" \"shell.zsh\" \"hook\" 2> /dev/null)"
if [ $? -eq 0 ]; then
    eval "$__conda_setup"
else
    if [ -f "${HOME}/opt/miniconda3/etc/profile.d/conda.sh" ]; then
        . "${HOME}/opt/miniconda3/etc/profile.d/conda.sh"
    else
        export PATH="${HOME}/opt/miniconda3/bin:$PATH"
    fi
fi
unset __conda_setup
# <<< conda initialize <<<

# Created by `pipx` on 2024-02-23 11:28:21
export PATH="$PATH:/Users/james.lawton/.local/bin"

# Add rustup to path.
export PATH="/opt/homebrew/opt/rustup/bin:$PATH"

# git-spice shell completion.
# eval "$(gs shell completion zsh)"
