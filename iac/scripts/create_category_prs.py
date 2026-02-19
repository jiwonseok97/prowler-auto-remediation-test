#!/usr/bin/env python3
"""Create category PRs and close stale PRs for same category/account."""
import argparse
import json
import subprocess
from pathlib import Path


def run(cmd: list[str], check: bool = True) -> str:
    p = subprocess.run(cmd, capture_output=True, text=True)
    if check and p.returncode != 0:
        raise RuntimeError(f"cmd failed: {' '.join(cmd)}\n{p.stderr}")
    return p.stdout.strip()


def main() -> None:
    p = argparse.ArgumentParser()
    p.add_argument("--root", required=True)
    p.add_argument("--manifest", required=True)
    p.add_argument("--account-id", required=True)
    p.add_argument("--run-id", required=True)
    a = p.parse_args()

    manifest = json.loads(Path(a.manifest).read_text(encoding="utf-8"))
    account = a.account_id

    for cat in manifest.get("categories", []):
        category = cat["category"]
        path = Path(cat["path"])
        if not path.exists():
            continue

        branch = f"remediation/{category}-{account}-{a.run_id}"

        # Close stale PRs for same category+account pattern.
        stale_prefix = f"remediation/{category}-{account}-"
        rows = run(["gh", "pr", "list", "--state", "open", "--json", "number,headRefName"], check=False)
        if rows:
            for pr in json.loads(rows):
                if pr["headRefName"].startswith(stale_prefix):
                    run(["gh", "pr", "close", str(pr["number"]), "--delete-branch"], check=False)

        run(["git", "checkout", "-B", branch])
        run(["git", "add", str(path)])
        run(["git", "add", str(Path(a.manifest))])
        run(["git", "commit", "-m", f"remediation: {category} {a.run_id}"], check=False)
        run(["git", "push", "-u", "origin", branch, "--force"])

        top5 = ", ".join(cat.get("top5", [])[:5])
        manual = "\n".join(f"- {x}" for x in cat.get("manual_required", [])) or "- none"
        body = (
            f"## Summary\n"
            f"- category: {category}\n"
            f"- checks: {cat.get('checks', 0)}\n"
            f"- top5: {top5}\n\n"
            f"## Impact\n"
            f"- path: {path}\n"
            f"- apply trigger: merge to main\n\n"
            f"## Verification\n"
            f"- merge PR\n"
            f"- apply workflow runs automatically\n"
            f"- rescan workflow reports FAIL delta\n\n"
            f"## Remaining Manual Required\n{manual}\n"
        )

        run(
            [
                "gh",
                "pr",
                "create",
                "--base",
                "main",
                "--head",
                branch,
                "--title",
                f"[AutoRemediation] {category} {account} {a.run_id}",
                "--body",
                body,
            ],
            check=False,
        )

    run(["git", "checkout", "main"], check=False)


if __name__ == "__main__":
    main()