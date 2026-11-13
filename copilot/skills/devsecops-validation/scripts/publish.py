#!/usr/bin/env python3

"""Publish validated JSON reports without overwriting existing files."""

import argparse
import json
import os
import stat
import sys
import tempfile
from pathlib import Path


def publish(source: Path, destination: Path) -> None:
    if not source.is_file():
        raise ValueError("Source report does not exist")

    with source.open("r", encoding="utf-8") as stream:
        report = json.load(stream)

    if not isinstance(report, dict):
        raise ValueError("Source report must be a JSON object")

    if not destination.parent.is_dir():
        raise ValueError("Destination directory does not exist")

    if destination.exists() or destination.is_symlink():
        raise FileExistsError("Destination already exists")

    descriptor, temporary = tempfile.mkstemp(
        prefix=".devsecops-publish-",
        suffix=".json",
        dir=destination.parent,
    )

    try:
        os.fchmod(descriptor, stat.S_IRUSR | stat.S_IWUSR)

        with os.fdopen(descriptor, "w", encoding="utf-8") as output:
            descriptor = -1
            json.dump(report, output, indent=2, sort_keys=True)
            output.write("\n")
            output.flush()
            os.fsync(output.fileno())

        os.link(temporary, destination)

        directory_fd = os.open(
            destination.parent,
            os.O_RDONLY | os.O_DIRECTORY,
        )

        try:
            os.fsync(directory_fd)
        finally:
            os.close(directory_fd)

    finally:
        if descriptor >= 0:
            os.close(descriptor)

        if os.path.exists(temporary):
            os.unlink(temporary)


def main() -> int:
    parser = argparse.ArgumentParser()

    parser.add_argument("source")
    parser.add_argument("destination")

    args = parser.parse_args()

    try:
        publish(
            Path(args.source),
            Path(args.destination),
        )

    except (OSError, ValueError, json.JSONDecodeError) as error:
        print(
            f"ERROR: JSON publishing failed: {error}",
            file=sys.stderr,
        )
        return 2

    print("PASS: Atomic JSON report published")
    return 0


if __name__ == "__main__":
    sys.exit(main())
