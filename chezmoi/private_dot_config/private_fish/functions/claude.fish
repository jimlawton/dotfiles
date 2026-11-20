function claude --wraps=claude --description 'Run claude with proxy'
    env HTTPS_PROXY=$AI_PROXY command claude $argv
end
