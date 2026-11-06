# Run Claude Code through the NROC nightly proxy. CLI apps ignore the system
# PAC file, so the proxy has to be set explicitly.

function claude --description 'Claude Code through the NROC nightly proxy'
    set -lx HTTPS_PROXY $AI_PROXY
    # The proxy refuses CONNECT (403) to any host it does not inspect, so
    # these must go direct. Add hosts here as they turn up broken.
    set -lx NO_PROXY (string join , \
        localhost \
        127.0.0.1 \
        ::1 \
        downloads.claude.ai \
        mcp-proxy.anthropic.com \
        github.com \
        api.github.com \
        codeload.github.com \
        raw.githubusercontent.com)
    command claude $argv
end
