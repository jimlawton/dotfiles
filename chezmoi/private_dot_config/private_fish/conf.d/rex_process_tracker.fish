# Only run in interactive shells inside a Rex pane
status is-interactive; or exit 0
set -q REX_BLOCK; or exit 0
set -q _rex_restore_loaded; and exit 0
set -g _rex_restore_loaded 1

set -l _state_base "$XDG_STATE_HOME"
test -z "$_state_base"; and set _state_base "$HOME/.local/state"

# ---------------------------------------------------------------------------
# 1. RexAgentRestore (1:1 port of rex-agent-restore.zsh)
# ---------------------------------------------------------------------------
set -g _rex_agent_first 1
if set -q REX_AGENT_RESTORE_STATE_DIR; and test -n "$REX_AGENT_RESTORE_STATE_DIR"
    set -g _rex_agent_dir "$REX_AGENT_RESTORE_STATE_DIR"
else
    set -g _rex_agent_dir "$_state_base/rex-agent-restore"
end

set -l _block_uuid (string replace -r '^block:' '' -- "$REX_BLOCK")
set -g _rex_agent_file "$_rex_agent_dir/panes/$_block_uuid.json"

if test "$_REX_AGENT_RESTORE_OWNER" = "$REX_BLOCK"
    set -g _rex_agent_nested 1
else
    set -g _rex_agent_nested 0
    set -gx _REX_AGENT_RESTORE_OWNER "$REX_BLOCK"
end

set -gx REX_AGENT_RESTORE_SHELL_TOKEN "$fish_pid-"(random)(random)"-"(date +%s)

function _rex_agent_killed -a code
    test "$code" = 129 -o "$code" = 137 -o "$code" = 143
end

function _rex_agent_run
    type -q rex-agent-restore; or return 0
    set -l plan (rex-agent-restore restore-plan 2>/dev/null); or return 0
    test (count $plan) -ge 3; or return 0

    set -l mode $plan
    set -l desc $plan
    set -l cmd (string join \n -- $plan[3..-1])
    test -n "$cmd"; or return 0

    switch $mode
        case off
            return 0
        case prompt
            echo "rex-agent-restore: press Enter to resume this pane's chat, or clear the line to skip."
            commandline -r -- "$cmd"
            return 0
    end

    set_color brblack
    echo "rex-agent-restore: $desc"
    set_color normal

    builtin history append -- "$cmd"
    eval "$cmd"
    set -l st $status
    _rex_agent_killed $st; or command rm -f -- "$_rex_agent_file"
    return 0
end

# ---------------------------------------------------------------------------
# 2. Active TUI / CLI Process Tracker & First-Prompt Restorer
# ---------------------------------------------------------------------------
set -g _rex_tui_dir "$_state_base/rex-active-cmds"
mkdir -p "$_rex_tui_dir"
set -g _rex_tui_first 1

function _rex_tui_restore_on_boot
    test "$_rex_tui_first" = 1 -a "$_rex_agent_nested" = 0; or return 0
    set -g _rex_tui_first 0

    set -l target_file "$_rex_tui_dir/$REX_BLOCK"

    # Pass 1: Match same REX_SESSION + PWD
    if not test -f "$target_file"
        for f in $_rex_tui_dir/block:*
            if test -f "$f"
                set -l fields (string split \t -- (head -n 1 "$f"))
                if test (count $fields) -ge 3; and test "$fields[1]" = "$REX_SESSION" -a "$fields[2]" = "$PWD"
                    set target_file "$f"
                    break
                end
            end
        end
    end

    # Pass 2: Fallback to PWD-only match if session ID also rotated
    if not test -f "$target_file"
        for f in $_rex_tui_dir/block:*
            if test -f "$f"
                set -l fields (string split \t -- (head -n 1 "$f"))
                if test (count $fields) -ge 3; and test "$fields[2]" = "$PWD"
                    set target_file "$f"
                    break
                end
            end
        end
    end

    if test -f "$target_file"
        set -l line (head -n 1 "$target_file")
        command rm -f -- "$target_file"
        set -l fields (string split -m 2 \t -- "$line")
        set -l cmd ""
        if test (count $fields) -ge 3
            set cmd "$fields[3]"
        else if test (count $fields) -eq 2
            set cmd "$fields[2]"
        end

        if test -n "$cmd"
            set_color brblack
            echo "rex-tui-restore: $cmd"
            set_color normal
            builtin history append -- "$cmd"
            # Re-record under the new REX_BLOCK so subsequent restarts also preserve it
            printf '%s\t%s\t%s\n' "$REX_SESSION" "$PWD" "$cmd" > "$_rex_tui_dir/$REX_BLOCK"
            eval "$cmd"
            set -l st $status
            if not _rex_agent_killed $st
                command rm -f -- "$_rex_tui_dir/$REX_BLOCK"
            end
        end
    end
end

function _rex_first_prompt --on-event fish_prompt
    set -l st $status
    # A. Handle RexAgentRestore
    if test -e "$_rex_agent_file"
        set -l body (string join \n < "$_rex_agent_file")
        if test -n "$REX_AGENT_RESTORE_SHELL_TOKEN"; and string match -q "*\"shell_token\":\"$REX_AGENT_RESTORE_SHELL_TOKEN\"*" -- "$body"
            _rex_agent_killed $st; or command rm -f -- "$_rex_agent_file"
        else if test "$_rex_agent_first" = 1 -a "$_rex_agent_nested" = 0
            set -g _rex_agent_first 0
            _rex_agent_run
        end
    end
    set -g _rex_agent_first 0

    # B. Handle TUI restore on first prompt of restored pane
    _rex_tui_restore_on_boot
end

function _rex_tui_start --on-event fish_preexec
    set -l cmd (string trim -- "$argv")
    if test -z "$cmd"; or string match -rq '^(exit|clear|logout)$' -- "$cmd"
        return
    end
    if string match -rq '^(env\s+)?([A-Za-z_][A-Za-z0-9_]*=[^\s]+\s+)*(claude|codex|opencode|pi)(\s|$)' -- "$cmd"
        return
    end
    printf '%s\t%s\t%s\n' "$REX_SESSION" "$PWD" "$cmd" > "$_rex_tui_dir/$REX_BLOCK"
end

function _rex_tui_end --on-event fish_postexec
    set -l st $status
    if not _rex_agent_killed $st
        command rm -f -- "$_rex_tui_dir/$REX_BLOCK"
    end
end

