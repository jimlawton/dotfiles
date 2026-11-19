# Load ready-to-run blocks by number instead of copying them from glow.
#   rtr 677          copy block 677 to the clipboard (paste with cmd-v)
#   677 then alt-r   replace the command line with block 677, unrun,
#                    so it can be read and edited before Enter
# Install: ln -s ~/nroc-scripts/supervisor/rtr.fish ~/.config/fish/conf.d/

function _rtr_block --argument-names n
    set -l f ~/nroc-scripts/out/ready-to-run.md
    awk -v n="$n" '$0 == "true # block " n {f=1} f && /^```/ {exit} f' $f
end

function rtr --description 'Copy ready-to-run block N to the clipboard'
    set -l b (_rtr_block $argv[1])
    if test (count $b) -eq 0
        echo "rtr: no block '$argv[1]'" >&2
        return 1
    end
    string join \n -- $b | pbcopy
    echo "rtr: block $argv[1] copied, "(count $b)" lines"
end

function _rtr_load --description 'Replace the command line with block N'
    set -l n (commandline -b | string trim)
    set -l b (_rtr_block $n)
    if test (count $b) -eq 0
        echo
        echo "rtr: no block '$n'" >&2
        commandline -f repaint
        return
    end
    commandline -r -- (string join \n -- $b)
end

bind alt-r _rtr_load
