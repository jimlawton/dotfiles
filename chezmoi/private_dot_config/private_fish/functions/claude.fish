function claude --wraps=claude --description 'Run claude with AI_PROXY and restore /rename title'
    # If resuming a session by ID, look up any saved custom-title in ~/.claude/projects
    for i in (seq (count $argv))
        if test "$argv[$i]" = "--resume" -o "$argv[$i]" = "-r"
            set -l next_idx (math $i + 1)
            if test $next_idx -le (count $argv)
                set -l sid "$argv[$next_idx]"
                set -l jsonl (find "$HOME/.claude/projects" -maxdepth 2 -name "$sid.jsonl" 2>/dev/null | head -n 1)
                if test -n "$jsonl"; and test -f "$jsonl"
                    # Extract the most recent customTitle from the transcript JSONL
                    set -l title (grep -o '"customTitle":"[^"]*"' "$jsonl" | tail -n 1 | sed 's/^"customTitle":"//;s/"$//')
                    if test -n "$title"
                        # Set terminal OSC title (updates Rex session/pane name)
                        printf '\033]0;%s\007' "$title"
                        if set -q REX_SESSION
                            rex api call session.set_label -d "{\"session_id\":\"$REX_SESSION\",\"label\":\"$title\"}" >/dev/null 2>&1
                        end
                    end
                end
            end
            break
        end
    end

    if set -q AI_PROXY; and test -n "$AI_PROXY"
        HTTPS_PROXY="$AI_PROXY" command claude $argv
    else
        command claude $argv
    end
end

