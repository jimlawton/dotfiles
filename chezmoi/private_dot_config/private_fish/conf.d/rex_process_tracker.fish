# Only run inside Rex blocks
if set -q REX_BLOCK
    set -g __rex_state_dir "$XDG_STATE_HOME/rex-active-cmds"
    if test -z "$XDG_STATE_HOME"
        set -g __rex_state_dir "$HOME/.local/state/rex-active-cmds"
    end
    mkdir -p "$__rex_state_dir"

    # Record command right before it executes
    function __rex_track_start --on-event fish_preexec
        set -l cmd (string trim -- "$argv[1]")
        # Skip empty commands, exit, or clear
        if test -z "$cmd"; or string match -rq '^(exit|clear|logout)$' -- "$cmd"
            return
        end
        # Write JSON/line with block ID, cwd, and exact command
        printf '%s\t%s\n' "$PWD" "$cmd" > "$__rex_state_dir/$REX_BLOCK"
    end

    # Delete the record as soon as the command finishes normally
    function __rex_track_end --on-event fish_postexec
        rm -f "$__rex_state_dir/$REX_BLOCK"
    end

    # Clean up if the user intentionally closes the shell/pane
    function __rex_track_exit --on-event fish_exit
        rm -f "$__rex_state_dir/$REX_BLOCK"
    end
end

