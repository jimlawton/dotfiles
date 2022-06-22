# Fig pre block. Keep at the top of this file.
[[ -f "$HOME/.fig/shell/bashrc.pre.bash" ]] && . "$HOME/.fig/shell/bashrc.pre.bash"
#!/bin/bash

########################################################################
# Bash non-interactive session setup
########################################################################

# Bash non-interactive shell will load the same functions as the interactive shell
source ~/.bash_profile

### MANAGED BY RANCHER DESKTOP START (DO NOT EDIT)
export PATH="/Users/james.lawton/.rd/bin:$PATH"
### MANAGED BY RANCHER DESKTOP END (DO NOT EDIT)

# Fig post block. Keep at the bottom of this file.
[[ -f "$HOME/.fig/shell/bashrc.post.bash" ]] && . "$HOME/.fig/shell/bashrc.post.bash"
