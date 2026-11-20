function claude --wraps=claude --description 'Run claude with AI_PROXY and restore /rename title'
    for i in (seq (count $argv))
        if test "$argv[$i]" = "--resume" -o "$argv[$i]" = "-r"
            set -l next_idx (math $i + 1)
            if test $next_idx -le (count $argv)
                set -l sid "$argv[$next_idx]"
                set -l title (python3 -c '
import glob, json, os, sys
sid = sys.argv[1]
for p in glob.glob(os.path.expanduser(f"~/.claude/projects/*/{sid}.jsonl")):
    title = ""
    with open(p, "r", encoding="utf-8", errors="ignore") as f:
        for line in f:
            if "customTitle" in line or "custom-title" in line:
                try:
                    obj = json.loads(line)
                    t = obj.get("customTitle") or obj.get("title")
                    if t:
                        title = t
                except Exception:
                    pass
    if title:
        print(title)
        break
' "$sid" 2>/dev/null)
                if test -n "$title"
                    printf '\033]0;%s\007' "$title"
                    if set -q REX_SESSION
                        rex api call session.set_label -d "{\"session_id\":\"$REX_SESSION\",\"label\":\"$title\"}" >/dev/null 2>&1
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

