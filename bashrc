# Fig pre block. Keep at the top of this file.
export PATH="${PATH}:${HOME}/.local/bin"
eval "$(fig init bash pre)"

#!/bin/bash

########################################################################
# Bash non-interactive session setup
########################################################################

# Bash non-interactive shell will load the same functions as the interactive shell
source ~/.bash_profile

# Fig post block. Keep at the bottom of this file.
eval "$(fig init bash post)"

