/opt/homebrew/bin/brew shellenv | source

fish_add_path $HOME/bin
fish_add_path $CARGO_HOME/bin

if status is-interactive
    # Make sure Tide is installed.
    fisher install IlanCosman/tide@v6

    # Commands to run in interactive sessions can go here
    set -x ATUIN_NOBIND true
    atuin init fish | source
    # Atuin keybindings to suppress -k warning
    bind ctrl-r _atuin_search
    bind up _atuin_bind_up
    bind \eOA _atuin_bind_up
    bind \e\[A _atuin_bind_up
    bind -M insert ctrl-r _atuin_search
    bind -M insert up _atuin_bind_up
    bind -M insert \eOA _atuin_bind_up
    bind -M insert \e\[A _atuin_bind_up
    source ~/dotfiles/shellvars-work
end
