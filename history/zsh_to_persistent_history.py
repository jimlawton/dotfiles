#!/usr/bin/env python3

"""Script to convert ZSH history to my Persistent History format."""

# Inspired by Eli Bendersky:
#  - http://eli.thegreenplace.net/2013/06/11/keeping-persistent-history-in-bash/
#  - https://github.com/eliben/code-for-blog/blob/master/2016/persistent-history/add-persistent-history.sh
#
# This was done per-entry when using the Bash shell, using the prompt strings.
# On moving to zsh and oh-my-zsh, this is no longer feasible.
# zsh stores its history in a particular format in ~/.zsh_history:
#
# : 1612182922:0;git st
# : 1612201796:0;history | tail
# : 1612201819:0;tail ~/.zsh_history
#
# The first integer is time since epoch, the second is runtime, the remainder of the line after ';'
# is the command line.
#
# This script is then run from cron:
# 0,15,30,45 * * * * python3 ~/dotfiles/history/zsh_to_persistent_history.py -w >/dev/null 2>&1 || true

import argparse
import sys
import os
import socket
import datetime
import shutil
import re
import filecmp
import glob


# Skip any potential credentials.
def _skip_line(combined_regex, line):
    ret = False
    if "API_KEY" in line or "PASSWORD" in line:
        ret = True
    if "$ARTIFACTORY_API_KEY" in line in line:
        ret = False
    if re.match(combined_regex, line):
        ret = True
    if ret:
        print(f"Skipping {line}")
    return ret


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "-w",
        "--write",
        action="store_true",
        dest="write",
        help="Write/overwrite the output file.",
    )
    parser.add_argument(
        "-s",
        "--sort",
        action="store_true",
        dest="sort",
        help="Sort the output, in ascending time order.",
    )
    parser.add_argument(
        "-i",
        "--infile",
        type=str,
        metavar="FILE",
        default="~/.persistent_history",
        help="Input persistent history file",
    )
    parser.add_argument(
        "-o",
        "--outfile",
        type=str,
        metavar="FILE",
        default="~/.persistent_history",
        help="Output persistent history file",
    )
    parser.add_argument(
        "-z",
        "--zfile",
        type=str,
        metavar="FILE",
        default="~/.zsh_history",
        help="Input ZSH history file",
    )
    parser.add_argument(
        "-e",
        "--extra-file",
        type=str,
        dest="extra_file",
        metavar="FILE",
        help="Extra input persistent history file",
    )
    parser.add_argument(
        "-I",
        "--iterm-files",
        type=str,
        dest="iterm_files",
        metavar="FILE",
        help="Extra input iTerm2 history file(s) - can be wild-carded",
    )
    args = parser.parse_args()

    infile = os.path.expanduser(args.infile)
    print(f"Input persistent history: {infile}")
    zfile = os.path.expanduser(args.zfile)
    print(f"Input ZSH history: {zfile}")
    outfile = os.path.expanduser(args.outfile)
    print(f"Output persistent history: {outfile}")

    extra_file = None
    if args.extra_file:
        extra_file = os.path.expanduser(args.extra_file)
        if not os.path.exists(extra_file):
            sys.exit(
                f"Error: extra history file {extra_file} does not exist!"
            )
        extra_file = os.path.abspath(extra_file)
        print(f"Extra ZSH input history file: {extra_file}")

    iterm_files = []
    if args.iterm_files:
        if '*' in args.iterm_files:
            print(args.iterm_files)
            iterm_file_list = glob.glob(os.path.expanduser(args.iterm_files))
            print(iterm_file_list)
            for filepath in iterm_file_list:
                iterm_files.append(os.path.abspath(filepath))
        else:
            iterm_files = [os.path.abspath(os.path.expanduser(args.iterm_files))]

    for iterm_file in iterm_files:
        if not os.path.exists(iterm_file):
            sys.exit(
                f"Error: extra history file {iterm_file} does not exist!"
            )
        print(f"Extra iTerm2 input history file: {iterm_file}")

    for filename in (infile, zfile):
        if not os.path.exists(filename):
            sys.exit(
                f"Error: input history file {filename} does not exist!"
            )

    if outfile != infile:
        if os.path.exists(outfile) and not args.write:
            sys.exit(
                f"Error: output persistent history file {outfile} already exists!"
            )

    real_infile = os.path.realpath(infile)
    if not os.path.exists(real_infile):
        sys.exit(
            f"Error: input history file {infile} is a symlink to {real_infile} which does not exist!"
        )
    print(f"Real input file: {real_infile}")

    real_outfile = os.path.realpath(outfile)
    print(f"Real output file: {real_outfile}")

    # Read input ZSH history file.
    with open(zfile, 'r', errors="ignore") as f:
        zdata = f.readlines()

    hostname = socket.gethostname().lower()
    user = os.getenv("USER")
    usernames = os.getenv("_USERNAMES")
    if usernames is None:
        usernames = [user]
    else:
        usernames = usernames.split()
        usernames.append(user)
        usernames = list(set(usernames))

    # Regexes to find occurrences of usernames not in paths.
    user_regexes = [f".*[^/]{user}[^/].*" for user in usernames]
    combined_regex = "(" + ")|(".join(user_regexes) + ")"

    # Read input ZSH history file.
    with open(infile, 'r', errors="ignore") as f:
        histdata = f.readlines()

    # Add the ZSH history to persistent history.
    for line in zdata:
        if not line.startswith(':') or ';' not in line:
            continue
        timestamp = int(line.split(':')[1].strip())
        time = datetime.datetime.fromtimestamp(timestamp)
        # duration = line.split(':')[2].strip().split(';')[0]
        cmd = line.split(';')[1].strip()
        if _skip_line(combined_regex, cmd):
            continue
        histdata.append(f"{hostname} | {time} | {cmd}\n")

    extra_data = []
    if extra_file:
        with open(extra_file, 'r', errors="ignore") as f:
            extra_data = f.readlines()
        histdata.extend(extra_data)

    iterm_data = []
    if iterm_files:
        for iterm_file in iterm_files:
            print(f"Reading {iterm_file}")
            with open(iterm_file, 'r', errors="ignore") as f:
                iterm_data = f.readlines()
            if len(iterm_data) % 2 != 0:
                sys.exit(f"Error: input file {iterm_file} does not have an even number of lines!")
            it = iter(iterm_data)
            for line in it:
                if not line.startswith('#'):
                    continue
                timestamp = int(line.split('#')[1].strip())
                time = datetime.datetime.fromtimestamp(timestamp)
                cmd = next(it).strip()
                if _skip_line(combined_regex, cmd):
                    continue
                histdata.append(f"{hostname} | {time} | {cmd}\n")

    # uniq the records.
    histdata = list(set(histdata))

    # Sort by the date field, ascending.
    # Keep the order of records at the same time unchanged.
    histdata = sorted(histdata, key=lambda x: "".join([x.split('|')[1], x.split('|')[0], x.split('|')[2]]))

    if args.write:

        if real_outfile == real_infile:
            # Save data to a temporary file.
            savefilename = f"{real_infile}.new"
        else:
            # Save data to output file.
            savefilename = f"{real_outfile}"

        print(f"Writing {savefilename} ...")
        with open(f"{savefilename}", 'w') as f:
            f.write(''.join(histdata))

        if real_outfile == real_infile:
            if filecmp.cmp(real_infile, savefilename, shallow=True):
                print(f"No changes, removing {savefilename} ...")
                os.remove(savefilename)
            else:
                # Now, move the files around.
                #  - infile -> infile.backup
                #  - outfile -> infile
                print(f"Moving {real_infile} to {real_infile}.backup ...")
                shutil.move(real_infile, f"{real_infile}.backup")
                print(f"Moving {savefilename} to {real_infile} ...")
                shutil.move(savefilename, real_infile)


if __name__ == "__main__":
    main()
