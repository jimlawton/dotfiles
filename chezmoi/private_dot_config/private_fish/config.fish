/opt/homebrew/bin/brew shellenv | source

fish_add_path $HOME/bin
fish_add_path $CARGO_HOME/bin

if status is-interactive
    # Commands to run in interactive sessions can go here

    # Starship prompt setup.
    function starship_transient_prompt_func
        "➜"
    end
    # function starship_transient_rprompt_func
    #    starship module time
    # end
    starship init fish | source
    enable_transience

    # Atuin setup.
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

    # Load sensitive variables.
    source ~/dotfiles/shellvars-work
end
