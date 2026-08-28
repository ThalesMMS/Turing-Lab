#!/usr/bin/env python3
"""Validate the issue roadmap and optionally compare it with GitHub."""

from __future__ import annotations

import argparse
import json
import subprocess
import sys
from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parents[1]
ROADMAP_PATH = REPO_ROOT / "docs" / "issue-roadmap.json"


def fail(messages: list[str]) -> int:
    print("Issue roadmap check failed:", file=sys.stderr)
    for message in messages:
        print(f"  {message}", file=sys.stderr)
    return 1


def github_open_issues() -> set[int]:
    result = subprocess.run(
        [
            "gh",
            "issue",
            "list",
            "--state",
            "open",
            "--limit",
            "1000",
            "--json",
            "number",
        ],
        cwd=REPO_ROOT,
        check=True,
        capture_output=True,
        text=True,
    )
    return {int(item["number"]) for item in json.loads(result.stdout)}


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--github",
        action="store_true",
        help="fail when an open GitHub issue is absent from the roadmap",
    )
    args = parser.parse_args()

    data = json.loads(ROADMAP_PATH.read_text(encoding="utf-8"))
    raw_issues = data.get("issues", {})
    profiles = data.get("verificationProfiles", {})
    issues = {int(number): item for number, item in raw_issues.items()}
    errors: list[str] = []

    if data.get("schemaVersion") != 1:
        errors.append("schemaVersion must be 1")
    if data.get("epic") not in issues:
        errors.append("epic must reference a tracked issue")

    for number, item in issues.items():
        phase = item.get("phase")
        dependencies = item.get("dependsOnIssues")
        phase_exit = item.get("dependsOnPhaseExit")
        profile = item.get("verificationProfile")
        if not isinstance(phase, int) or phase not in range(10):
            errors.append(f"#{number}: phase must be an integer from 0 through 9")
        if not isinstance(dependencies, list) or not all(
            isinstance(dependency, int) for dependency in dependencies
        ):
            errors.append(f"#{number}: dependsOnIssues must be an integer list")
            dependencies = []
        if number in dependencies:
            errors.append(f"#{number}: issue cannot depend on itself")
        for dependency in dependencies:
            if dependency not in issues:
                errors.append(f"#{number}: dependency #{dependency} is not tracked")
        if phase == 0 and phase_exit is not None:
            errors.append(f"#{number}: phase 0 cannot depend on a phase exit")
        if isinstance(phase, int) and phase > 0 and phase_exit != phase - 1:
            errors.append(f"#{number}: dependsOnPhaseExit must be {phase - 1}")
        commands = profiles.get(profile)
        if not isinstance(commands, list) or not commands:
            errors.append(f"#{number}: verificationProfile {profile!r} has no commands")

    visiting: set[int] = set()
    visited: set[int] = set()

    def visit(number: int) -> None:
        if number in visiting:
            errors.append(f"dependency cycle includes #{number}")
            return
        if number in visited:
            return
        visiting.add(number)
        for dependency in issues[number].get("dependsOnIssues", []):
            if dependency in issues:
                visit(dependency)
        visiting.remove(number)
        visited.add(number)

    for number in issues:
        visit(number)

    if args.github:
        try:
            missing = sorted(github_open_issues() - set(issues))
        except (FileNotFoundError, subprocess.CalledProcessError, json.JSONDecodeError) as error:
            errors.append(f"GitHub comparison could not run: {error}")
        else:
            if missing:
                errors.append(
                    "open GitHub issues missing from roadmap: "
                    + ", ".join(f"#{number}" for number in missing)
                )

    if errors:
        return fail(errors)

    suffix = " and covers every open GitHub issue" if args.github else ""
    print(f"Issue roadmap check passed for {len(issues)} tracked issues{suffix}.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
