function claude --wraps=claude --description 'Run claude with AI_PROXY'
    if set -q AI_PROXY; and test -n "$AI_PROXY"
        HTTPS_PROXY="$AI_PROXY" command claude $argv
    else
        command claude $argv
    end
end
