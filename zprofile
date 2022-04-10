# Fig pre block. Keep at the top of this file.
export PATH="${PATH}:${HOME}/.local/bin"
eval "$(fig init zsh pre)"

##############################################################################
# Import the shell-agnostic (Bash or Zsh) environment config
##############################################################################
source ~/.profile

##############################################################################
# rupa/z setup (path frecency with tab completion)
##############################################################################
source ~/dotfiles/z/z.sh

# Fig post block. Keep at the bottom of this file.
eval "$(fig init zsh post)"

