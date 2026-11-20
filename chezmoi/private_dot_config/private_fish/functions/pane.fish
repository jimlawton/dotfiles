# Open one of the supervisor's status files in glow.
#   pane              ready-to-run.md
#   pane pr-status    pr-status.md (also: open-items, agent-status,
#                     jira-tickets, ready-to-run)
# Install: cp ~/nroc-scripts/supervisor/pane.fish ~/.config/fish/functions/

function pane --description 'Open a supervisor status file in glow'
    set -l name ready-to-run
    set -q argv[1]; and set name $argv[1]
    set -l f ~/nroc-scripts/out/$name.md
    if not test -f $f
        echo "pane: no $f" >&2
        echo "pane: try ready-to-run, open-items, agent-status," \
            "pr-status or jira-tickets" >&2
        return 1
    end
    set -l s ~/nroc-scripts/glow/nroc.json
    # Rewrite the file a second after glow starts, so its watcher
    # renders the current contents.
    set -l py 'import pathlib,sys; p=pathlib.Path(sys.argv[1]); p.write_bytes(p.read_bytes())'
    fish -c "sleep 1; python3 -c '$py' $f" &
    glow --tui -s $s $f
end

complete -c pane -f -a 'ready-to-run open-items agent-status pr-status jira-tickets'
