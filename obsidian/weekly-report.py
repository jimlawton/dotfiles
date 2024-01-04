#!/usr/bin/env python3

# Simple script for Obsidian, to generate a new weekly note.

import argparse
import datetime
import glob
import os
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
        weekday_today = datetime.datetime.now().weekday()
        if weekday_today >= 4:
            end_date = datetime.datetime.now() - datetime.timedelta(weekday_today - 4)
        else:
            end_date = datetime.datetime.now() - datetime.timedelta(weeks=1) + datetime.timedelta(4 - weekday_today)
        date_str = end_date.strftime('%Y-%m-%d')

    curr_date_obj = datetime.datetime.strptime(date_str, '%Y-%m-%d')

    home = os.getenv('HOME')
    if home is None:
        sys.exit("$HOME is not defined!")

    now = datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S')
    year = curr_date_obj.strftime('%Y')
    month = curr_date_obj.strftime('%m')

    vault = f"{home}/obsidian/Notes"
    daily_dir = f"{vault}/Daily Notes/"
    weekly_dir = f"{vault}/Weekly Reports/"

    # Get a dict of all daily notes, with paths.
    daily_dict = {}
    daily_date_objs = []
    files = glob.glob(daily_dir + '/**/Daily*.md', recursive=True)
    for file_path in sorted(files):
        note_date = file_path.split('/')[-1].split('.')[0].split()[1]
        daily_dict[note_date] = file_path
        daily_date_objs.append(datetime.datetime.strptime(note_date, "%Y-%m-%d"))

    # Get a dict of all weekly notes, with paths.
    weekly_dict = {}
    weekly_date_objs = []
    files = glob.glob(weekly_dir + '/**/Weekly*.md', recursive=True)
    for file_path in sorted(files):
        note_date = file_path.split('/')[-1].split('.')[0].split()[1]
        weekly_dict[note_date] = file_path
        weekly_date_objs.append(datetime.datetime.strptime(note_date, "%Y-%m-%d"))

    if date_str in weekly_dict.keys():
        sys.exit(f"Weekly report for {date_str} already exists, skipping!")
    else:
        print(f"Creating weekly report for w/e {date_str}...")

    last_date_obj = weekly_date_objs[-1]

    # Find previous date.
    prev_date = max(d for d in weekly_date_objs if d < curr_date_obj)
    prev_str = prev_date.strftime('%Y-%m-%d')

    if curr_date_obj < last_date_obj:
        next_date = min(d for d in weekly_date_objs if d > curr_date_obj)
    else:
        next_date = datetime.datetime.strptime(date_str, '%Y-%m-%d') + datetime.timedelta(days=7)
    next_str = next_date.strftime('%Y-%m-%d')
    print(f"Next weekly report: {next_str}")

    file_lines = []

    # Read the previous weekly report file.
    prev_file_path = weekly_dict[prev_str]
    print(f"Reading from {prev_file_path}")

    prev_data_lines = []
    with open(prev_file_path, 'r') as f:
        prev_data_lines = f.readlines()

    output_dir_path = f"{weekly_dir + year + '/' + month}"
    if not os.path.isdir(output_dir_path):
        os.makedirs(output_dir_path, exist_ok=True)

    output_file_path = f"{output_dir_path + '/' + 'Weekly ' + date_str + '.md'}"

    # Generate front matter
    file_lines.append("---")
    file_lines.append(f"creation date: {now}")
    file_lines.append(f"tag: daily daily/{year}")
    file_lines.append("---")
    file_lines.append("")

    # Generate nav bar
    file_lines.append(f"<< [[Weekly {prev_str}]] | [[Weekly {next_str}]] >>")
    file_lines.append("")

    file_lines.append("## Activities this week")
    start = end = 0
    for i, line in enumerate(prev_data_lines):
        if line.startswith("## Planned for next week"):
            start = i + 1
        if line.startswith("## Backlog") and start > 0:
            end = i - 1
    planned_lines = prev_data_lines[start:end]
    # Populate activities with planned from last week, plus FIXME.
    for line in planned_lines:
        file_lines.append(line.strip('\n').replace("- ", "- `FIXME` "))

    # Extract all activities from daily reports since last weekly report.
    prev_dates = [d for d in daily_date_objs if prev_date < d <= curr_date_obj]
    prev_data_lines = []
    for d in prev_dates:
        d_str = d.strftime("%Y-%m-%d")
        prev_file_path = daily_dict[d_str]
        print(f"Reading from {prev_file_path}")
        with open(prev_file_path, 'r') as f:
            start = 0
            daily_lines = f.readlines()
            for i, line in enumerate(daily_lines):
                if line.startswith("## Activities"):
                    start = i + 1
            daily_lines = daily_lines[start:]
            daily_lines_tmp = []
            for line in daily_lines:
                if line.strip() == '-':
                    continue
                if line.startswith("- "):
                    daily_lines_tmp.append(f"- {d_str} {line[2:]}")
                else:
                    daily_lines_tmp.append(line)
            prev_data_lines.extend(daily_lines_tmp)
    prev_data_lines = [line.strip('\n') for line in prev_data_lines if line.strip() != '-']
    file_lines.extend(prev_data_lines)
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
