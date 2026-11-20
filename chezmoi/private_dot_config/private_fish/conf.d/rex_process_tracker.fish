if set -q REX_BLOCK
    set -g __rex_state_dir "$XDG_STATE_HOME/rex-active-cmds"
    if test -z "$XDG_STATE_HOME"
        set -g __rex_state_dir "$HOME/.local/state/rex-active-cmds"
    end
    mkdir -p "$__rex_state_dir"

    function __rex_track_start --on-event fish_preexec
        set -l cmd (string trim -- "$argv")
        # Ignore empty commands or shell exits
        if test -z "$cmd"; or string match -rq '^(exit|clear|logout)$' -- "$cmd"
            return
        end
        # Skip coding agents handled separately by RexAgentRestore
        if string match -rq '^(claude|codex|opencode|pi)(\s|$)' -- "$cmd"
            return
        end
        printf '%s\t%s\n' "$PWD" "$cmd" > "$__rex_state_dir/$REX_BLOCK"
    end

    function __rex_track_end --on-event fish_postexec
        rm -f "$__rex_state_dir/$REX_BLOCK"
    end

    function __rex_track_exit --on-event fish_exit
        rm -f "$__rex_state_dir/$REX_BLOCK"
    end
end

