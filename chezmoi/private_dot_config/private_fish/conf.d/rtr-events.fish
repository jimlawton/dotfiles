# Log each ready-to-run block as it starts and ends, so the supervisor
# sees it without being told. Fires only for a command line whose first
# line is "true # block NNN". Writes ~/nroc-scripts/out/run-events.log:
#   time  start  NNN  pane
#   time  end    NNN  pane  rc   (rc empty: stopped before "set rc")
# Install: copy beside rtr.fish in ~/.config/fish/conf.d/

set -g _rtr_log ~/nroc-scripts/out/run-events.log

function _rtr_preexec --on-event fish_preexec
    set -l m (string match -r -- '^true # block (\d+)' $argv[1])
    set -q m[2]; or return
    set -g _rtr_running $m[2]
    set -e -g rc
    printf '%s\tstart\t%s\t%s\n' (date -u +%FT%TZ) $m[2] \
        "$REX_BLOCK" >>$_rtr_log
end

function _rtr_postexec --on-event fish_postexec
    set -q _rtr_running; or return
    printf '%s\tend\t%s\t%s\t%s\n' (date -u +%FT%TZ) $_rtr_running \
        "$REX_BLOCK" "$rc" >>$_rtr_log
    set -e -g _rtr_running
end
