export OS=$(uname -s)

#########################################################################
# Tool settings
#########################################################################

# Set the default pager to less
set -gx PAGER less
# Set less to have a default flag of -R (RAW) so color passes through
set pgx LESS "-R"

set -gx HOSTNAME `hostname -s`
set -gx EDITOR vim
set -gx TMOUT 0

set -gx PYTHONSTARTUP $HOME/.pythonrc
set -gx WORKON_HOME $HOME/.virtualenvs
set -gx PIP_VIRTUALENV_BASE $WORKON_HOME
set -gx PIP_RESPECT_VIRTUALENV true
set -gx PIP_REQUIRE_VIRTUALENV true

set -gx PYENV_ROOT $HOME/.pyenv

set -gx GOPATH $HOME/go
set -gx GOENV_ROOT $HOME/.goenv

set -gx TSRC_PARALLEL_JOBS 8

if test -f $HOME/dotfiles/shellvars-personal
    source $HOME/dotfiles/shellvars-personal
end
if test -f $HOME/dotfiles/shellvars-work
    source $HOME/dotfiles/shellvars-work
end
