#!/usr/bin/env python3

"""Script to convert my Persistent History format to CSV for use with Atuin."""

# The Persistent History file is in the format:
#   hostname | date-time | command
# example:
#  `mbp-70wql7 | 2025-10-31 14:36:30 | crontab -l`
#
# The CSV file is in the format:
#   timestamp,hostname,command
# example:
# `,mbp-70wql7,crontab -l`

import argparse
import csv
import os
import sys
from datetime import datetime


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
        help="Output CSV file",
    )
    args = parser.parse_args()

    infile = os.path.expanduser(args.infile)
    print(f"Input persistent history: {infile}")

    if not args.outfile:
        sys.exit("Error: output CSV file must be specified with -o/--outfile")

    outfile = os.path.expanduser(args.outfile)
    print(f"Output CSV history: {outfile}")

    if not os.path.exists(infile):
        sys.exit(f"Error: input history file {infile} does not exist!")

    if os.path.exists(outfile) and not args.write:
        sys.exit(f"Error: output persistent history file {outfile} already exists!")

    real_infile = os.path.realpath(infile)
    if not os.path.exists(real_infile):
        sys.exit(
            f"Error: input history file {infile} is a symlink to {real_infile} which does not exist!"
        )
    print(f"Real input file: {real_infile}")

    real_outfile = os.path.realpath(outfile)
    print(f"Real output file: {real_outfile}")

    # Read input persistent history file.
    with open(infile, "r", errors="ignore") as f:
        histdata = f.readlines()

    outrows = []
    bad_count = 0
    bad_hostname_count = 0
    bad_time_count = 0
    for i, inline in enumerate(range(len(histdata))):
        parts = histdata[inline].strip().split("|")
        if len(parts) < 3:
            print(f"Warning: skipping malformed line: {histdata[inline].strip()}")
            continue
        # Split only on the first 2 pipes, since the command may contain pipes
        parts = histdata[inline].strip().split("|", 2)
        hostname = parts[0].strip()
        if (
            hostname == "unknown"
            or hostname.endswith(".local")
            or hostname.endswith(".station")
        ):
            print(
                f"Warning: skipping line {i} with invalid hostname: {histdata[inline].strip()}"
            )
            bad_count += 1
            bad_hostname_count += 1
            # continue
        date_time = parts[1].strip()
        # Convert datetime string to seconds since epoch
        try:
            dt_obj = datetime.strptime(date_time, "%Y-%m-%d %H:%M:%S")
            timestamp = int(dt_obj.timestamp())
        except ValueError:
            print(
                f"Warning: skipping line {i} with invalid datetime format: {histdata[inline].strip()}"
            )
            bad_count += 1
            bad_time_count += 1
            continue
        # Command is everything after the second pipe to the end of the line.
        command = parts[2].strip()
        # Set the duration to zero always, as we don't have that info.
        outrows.append((timestamp, 0, hostname, command))

    # TODO uniq the records?
    # TODO Sort by the date field, ascending?

    if args.write:
        savefilename = f"{real_outfile}"
        print(f"Writing {savefilename} ...")
        with open(f"{savefilename}", "w") as f:
            writer = csv.writer(f, quoting=csv.QUOTE_MINIMAL)
            # Write header row.
            writer.writerow(["timestamp", "duration", "hostname", "command"])
            # Write outrows to CSV file.
            for row in outrows:
                writer.writerow(row)

    print(f"Processed {len(outrows)} valid history lines.")
    if bad_count > 0:
        print(f"Skipped {bad_count} bad lines:")
        if bad_hostname_count > 0:
            print(f"  {bad_hostname_count} lines with bad hostnames.")
        if bad_time_count > 0:
            print(f"  {bad_time_count} lines with bad date/time formats.")


if __name__ == "__main__":
    main()
