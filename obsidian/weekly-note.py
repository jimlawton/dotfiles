#!/usr/bin/env python3

# Simple script for Obsidian, to generate a new weekly note.

import argparse
import datetime
import glob
import os
import subprocess
import sys


def main():
    """Generate a EasyConnect connection request."""

    parser = argparse.ArgumentParser()
    parser.add_argument(
        type=str,
        dest="date",
        metavar="DATE",
        nargs="?",
        help="Optional date",
    )
    args = parser.parse_args()

    if args.date:
        try:
            datetime.datetime.strptime(args.date, '%Y-%m-%d')
            date_str = args.date
        except ValueError:
            sys.exit("Invalid date, must be valid calendar date in the form YYYY-MM-DD!")
    else:
        date_str = datetime.datetime.today().strftime('%Y-%m-%d')

    curr_date_obj = datetime.datetime.strptime(date_str, '%Y-%m-%d')

    home = os.getenv('HOME')
    if home is None:
        sys.exit("$HOME is not defined!")

    now = datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S')
    year = curr_date_obj.strftime('%Y')
    month = curr_date_obj.strftime('%m')

    vault = f"{home}/obsidian/Notes"
    notes_dir = f"{vault}/Weekly Reports/"

    # get a dict of all weekly notes, with paths.
    notes_dict = {}
    date_objs = []
    files = glob.glob(notes_dir + '/**/Weekly*.md', recursive=True)
    for file_path in sorted(files):
        note_date = file_path.split('/')[-1].split('.')[0].split()[1]
        notes_dict[note_date] = file_path
        date_objs.append(datetime.datetime.strptime(note_date, "%Y-%m-%d"))

    if date_str in notes_dict.keys():
        sys.exit(f"Weekly report for {date_str} already exists, skipping!")
    else:
        print(f"Creating weekly report for w/e {date_str}...")

    last_date_obj = date_objs[-1]

    # note_dates = sorted(notes_dict.keys())

    # Find previous date.
    prev_date = max(d for d in date_objs if d < curr_date_obj)
    prev_str = prev_date.strftime('%Y-%m-%d')

    # Find next date. This depends on whether we're creating a note in a date gap, or adding at the end.
    if curr_date_obj < last_date_obj:
        next_date = min(d for d in date_objs if d > curr_date_obj)
    else:
        next_date = datetime.datetime.strptime(date_str, '%Y-%m-%d') + datetime.timedelta(days=7)
    next_str = next_date.strftime('%Y-%m-%d')

    file_lines = []

    # Read the previous note file.
    prev_file_path = notes_dict[prev_str]
    print(f"Reading from {prev_file_path}")

    prev_data_lines = []
    with open(prev_file_path, 'r') as f:
        prev_data_lines = f.readlines()

    output_file_path = f"{notes_dir + year + '/' + month + '/' + 'Weekly ' + date_str + '.md'}"

    # Generate front matter
    file_lines.append("---")
    file_lines.append(f"creation date: {now}")
    file_lines.append(f"tag: daily daily/{year}")
    file_lines.append("---")
    file_lines.append("")

    # Generate nav bar
    file_lines.append(f"<< [[Weekly {prev_str}]] | [[Weekly {next_str}]] >>")
    file_lines.append("")

    # Populate activities with planned from last week, plus FIXME.
    file_lines.append("## Activities this week")
    start = end = 0
    for i, line in enumerate(prev_data_lines):
        if line.startswith("## Planned for next week"):
            start = i + 1
        if line.startswith("## Backlog") and start > 0:
            end = i - 1
    planned_lines = prev_data_lines[start:end]
    for line in planned_lines:
        file_lines.append(line.strip('\n').replace("- ", "- `FIXME` "))
    file_lines.append("")

    file_lines.append("## Planned for next week")
    file_lines.append("- ")
    file_lines.append("")

    file_lines.append("## Backlog")
    file_lines.append("- ")
    file_lines.append("")

    # Write new file
    print(f"Writing to {output_file_path}")
    with open(output_file_path, 'w') as f:
        f.write('\n'.join(file_lines))


if __name__ == "__main__":
    main()
