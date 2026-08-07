abbr --add hexdumpfile 'od -h'

abbr --add gpl 'git pull'
abbr --add gps 'git push'

# Directory listings
# -G Add colors to ls
# -l Long format
# -h Short size suffixes (B, K, M, G, P)
# -p Postpend slash to folders
# abbr --add ls 'ls -G -h -p '
# abbr --add ll 'ls -l -G -h -p '

abbr --add grep 'grep --color=auto --exclude=.git'
abbr --add egrep 'egrep --color=auto --exclude=.git'
abbr --add fgrep 'fgrep --color=auto --exclude=.git'

# abbr --add rm 'rm -i'
# abbr --add cp 'cp -i'
# abbr --add mv 'mv -i'

# abbr --add now 'date +"%Y%m%d-%H%M%S"'
abbr --add minicom 'minicom -C minicom-`now`.log'
abbr --add pgrep 'ps auxww | grep \!* | grep -v grep'
abbr --add a2ps 'a2ps --landscape -1 --line-numbers=5 --pretty-print --highlight-level=heavy --chars-per-line=120 --sides=duplex --prologue=color'
abbr --add gatekeeper 'sudo xattr -d com.apple.quarantine'

# On Mac OSX, uuidgen produces uppercase.
abbr --add uuidgen 'uuidgen | tr "[:upper:]" "[:lower:]"'

# Ping Artifactory.
abbr --add afping 'curl -I https:/${ARTIFACTORY_EMAIL}:${ARTIFACTORY_API_KEY}@${ARTIFACTORY_BASE}/artifactory/api/system/ping'

# Use zoxide instead of cd
abbr --add cd 'z'

# Use bat instead of cat
abbr --add cat 'bat'

# Use ls replacement eza to list the directory tree
abbr --add ll 'eza -lhT --git'

# gs abbreviation for git-spice
abbr --add gs 'git-spice'

# roborev abbreviations
abbr --add rr-branch-review 'roborev review --branch --agent codex --reasoning xhigh'

