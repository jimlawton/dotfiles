if set -q REX_BLOCK
    set -g __rex_state_dir "$XDG_STATE_HOME/rex-active-cmds"
    set -g __rex_agent_state_dir "$XDG_STATE_HOME/rex-agent-restore"
    if test -z "$XDG_STATE_HOME"
        set -g __rex_state_dir "$HOME/.local/state/rex-active-cmds"
        set -g __rex_agent_state_dir "$HOME/.local/state/rex-agent-restore"
    end
    mkdir -p "$__rex_state_dir"

    # Forget agent chat when you quit the agent normally and return to Fish
    function __rex_agent_forget --on-event fish_prompt
        if test -e "$__rex_agent_state_dir/$REX_BLOCK"
            rm -rf "$__rex_agent_state_dir/$REX_BLOCK"
        end
    end

    function __rex_track_start --on-event fish_preexec
        set -l cmd (string trim -- "$argv")
        if test -z "$cmd"; or string match -rq '^(exit|clear|logout)$' -- "$cmd"
            return
        end
        if string match -rq '^(env\s+)?([A-Za-z_][A-Za-z0-9_]*=[^\s]+\s+)*(claude|codex|opencode|pi)(\s|$)' -- "$cmd"
            return
        end
        printf '%s\t%s\n' "$PWD" "$cmd" > "$__rex_state_dir/$REX_BLOCK"
    end

    function __rex_track_end --on-event fish_postexec
        rm -f "$__rex_state_dir/$REX_BLOCK"
    end

    function __rex_track_exit --on-event fish_exit
        rm -f "$__rex_state_dir/$REX_BLOCK"
        rm -rf "$__rex_agent_state_dir/$REX_BLOCK"
    end
end

