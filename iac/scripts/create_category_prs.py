#!/usr/bin/env python3
"""Create category PRs and close stale PRs for same category/account."""
import argparse
import json
import subprocess
import shutil
import tempfile
from pathlib import Path


def run(cmd: list[str], check: bool = True) -> str:
    p = subprocess.run(cmd, capture_output=True, text=True)
    if check and p.returncode != 0:
        raise RuntimeError(f"cmd failed: {' '.join(cmd)}\n{p.stderr}")
    if not check and p.returncode != 0 and p.stderr:
        print(p.stderr.strip())
    return p.stdout.strip()


def has_staged_changes() -> bool:
    p = subprocess.run(["git", "diff", "--cached", "--quiet"])
    return p.returncode != 0


def staged_files(prefix: Path) -> list[str]:
    out = run(["git", "diff", "--cached", "--name-only", "--", str(prefix)], check=False)
    return [line.strip() for line in out.splitlines() if line.strip()]


def create_single_pr(
    manifest: dict,
    source_root: Path,
    run_id: str,
    open_prs: list[dict],
) -> None:
    branch_prefix = "remediation/all"
    branch = f"{branch_prefix}-{run_id}"
    message = "PR-merge / remediation: all-categories"
    target_root = Path("remediation")

    for pr in open_prs:
        head = str(pr.get("headRefName", ""))
        number = pr.get("number")
        if not number:
            continue
        if head == branch:
            continue
        if head == branch_prefix or head.startswith(f"{branch_prefix}-"):
            run(
                [
                    "gh",
                    "pr",
                    "close",
                    str(number),
                    "--comment",
                    f"Superseded by newer remediation run branch `{branch}`.",
                ],
                check=False,
            )

    run(["git", "checkout", "main"], check=False)
    run(["git", "checkout", "-B", branch, "main"])

    if target_root.exists():
        shutil.rmtree(target_root)
    target_root.mkdir(parents=True, exist_ok=True)
    source_manifest = source_root / "manifest.json"
    if source_manifest.exists():
        shutil.copy2(source_manifest, target_root / "manifest.json")

    included_categories: list[str] = []
    total_checks = 0
    safe_auto = 0
    review_then_apply = 0
    manual_runbook = 0
    top5_all: list[str] = []

    for cat in manifest.get("categories", []):
        category = str(cat.get("category", "")).strip()
        if not category:
            continue
        source_path = source_root / category
        if not source_path.exists():
            continue
        if not any(source_path.glob("*.tf")):
            continue
        shutil.copytree(source_path, target_root / category)
        included_categories.append(category)
        total_checks += int(cat.get("checks", 0))
        tiers = cat.get("tier_breakdown", {}) if isinstance(cat.get("tier_breakdown"), dict) else {}
        safe_auto += int(tiers.get("safe-auto", 0))
        review_then_apply += int(tiers.get("review-then-apply", 0))
        manual_runbook += int(tiers.get("manual-runbook", 0))
        for cid in cat.get("top5", [])[:5]:
            if cid and cid not in top5_all:
                top5_all.append(cid)

    if not included_categories:
        print("skip single-pr: no terraform categories to include")
        run(["git", "checkout", "main"], check=False)
        return

    manifest_path = Path("remediation/manifest.json")
    if manifest_path.exists():
        run(["git", "add", str(manifest_path)], check=False)
    run(["git", "add", str(target_root)], check=False)

    changed_in_root = staged_files(target_root)
    tf_changed = any(x.endswith(".tf") for x in changed_in_root)
    if not tf_changed:
        print("skip single-pr: no terraform changes")
        run(["git", "reset", "--", str(target_root)], check=False)
        run(["git", "checkout", "main"], check=False)
        return
    if not has_staged_changes():
        print("skip single-pr: no staged changes")
        run(["git", "checkout", "main"], check=False)
        return

    run(["git", "commit", "-m", message], check=False)
    run(["git", "push", "-u", "origin", branch])

    top5 = "\n".join(f"- {x}" for x in top5_all[:5]) or "- none"
    cats = ", ".join(f"`{x}`" for x in included_categories)
    body = (
        "## What This PR Changes\n"
        "- Mode: `single-pr` (demo)\n"
        f"- Categories: {cats}\n"
        f"- Generated Terraform checks: `{total_checks}`\n\n"
        "## Execution Tiers\n"
        f"- safe-auto: `{safe_auto}`\n"
        f"- review-then-apply: `{review_then_apply}`\n"
        f"- manual-runbook: `{manual_runbook}`\n\n"
        "## Priority (Top 5)\n"
        f"{top5}\n\n"
        "## Merge Impact\n"
        "- This single PR merge triggers `Security Pipeline - 03 Apply Merged Generated Terraform Remediation` once.\n"
        "- Designed for a one-shot demo of FAIL reduction.\n"
    )

    p = subprocess.run(
        [
            "gh",
            "pr",
            "create",
            "--base",
            "main",
            "--head",
            branch,
            "--title",
            message,
            "--body",
            body,
        ],
        capture_output=True,
        text=True,
    )
    if p.returncode != 0:
        err = (p.stderr or "").strip()
        if "not permitted to create or approve pull requests" in err.lower():
            print("warn: single PR create skipped by repo policy")
        else:
            raise RuntimeError(f"cmd failed: gh pr create\n{err}")

    run(["git", "checkout", "main"], check=False)


def main() -> None:
    p = argparse.ArgumentParser()
    p.add_argument("--root", required=True)
    p.add_argument("--manifest", required=True)
    p.add_argument("--account-id", required=True)
    p.add_argument("--run-id", required=True)
    p.add_argument("--single-pr", action="store_true")
    a = p.parse_args()

    manifest = json.loads(Path(a.manifest).read_text(encoding="utf-8"))
    run(["git", "config", "user.name", "github-actions[bot]"], check=False)
    run(["git", "config", "user.email", "41898282+github-actions[bot]@users.noreply.github.com"], check=False)

    open_prs_raw = run(["gh", "pr", "list", "--state", "open", "--json", "number,headRefName,title"], check=False)
    open_prs = json.loads(open_prs_raw) if open_prs_raw else []

    source_root = Path(a.root).resolve()
    with tempfile.TemporaryDirectory(prefix="remediation-prs-") as td:
        snapshot_root = Path(td) / "snapshot"
        shutil.copytree(source_root, snapshot_root)

        if a.single_pr:
            create_single_pr(manifest, snapshot_root, a.run_id, open_prs)
            return

        for cat in manifest.get("categories", []):
            category = cat["category"]
            path = Path(cat["path"])
            source_path = snapshot_root / category
            if not source_path.exists():
                continue
            if not any(source_path.glob("*.tf")):
                print(f"skip {category}: no terraform files")
                continue

            branch_prefix = f"remediation/{category}"
            branch = f"{branch_prefix}-{a.run_id}"
            message = f"PR-merge / remediation: {category}"

            # Close stale PRs for the same category before creating a new run-scoped branch PR.
            for pr in open_prs:
                head = str(pr.get("headRefName", ""))
                number = pr.get("number")
                if not number:
                    continue
                if head == branch:
                    continue
                if head == branch_prefix or head.startswith(f"{branch_prefix}-"):
                    run(
                        [
                            "gh",
                            "pr",
                            "close",
                            str(number),
                            "--comment",
                            f"Superseded by newer remediation run branch `{branch}`.",
                        ],
                        check=False,
                    )

            run(["git", "checkout", "main"], check=False)
            run(["git", "checkout", "-B", branch, "main"])

            # Sync generated category files from the snapshot into the branch workspace.
            if path.exists():
                shutil.rmtree(path)
            path.parent.mkdir(parents=True, exist_ok=True)
            shutil.copytree(source_path, path)

            run(["git", "add", str(path)], check=False)
            changed_in_category = staged_files(path)
            tf_changed = any(x.endswith(".tf") for x in changed_in_category)
            if not tf_changed:
                print(f"skip {category}: no terraform changes in category path")
                run(["git", "reset", "--", str(path)], check=False)
                run(["git", "checkout", "main"], check=False)
                continue
            if not has_staged_changes():
                print(f"skip {category}: no file changes")
                run(["git", "checkout", "main"], check=False)
                continue
            run(["git", "commit", "-m", message], check=False)
            run(["git", "push", "-u", "origin", branch])

            top5 = "\n".join(f"- {x}" for x in cat.get("top5", [])[:5]) or "- none"
            manual = "\n".join(f"- {x}" for x in cat.get("manual_required", [])) or "- none"
            tiers = cat.get("tier_breakdown", {}) if isinstance(cat.get("tier_breakdown"), dict) else {}
            tier_lines = (
                f"- safe-auto: `{int(tiers.get('safe-auto', 0))}`\n"
                f"- review-then-apply: `{int(tiers.get('review-then-apply', 0))}`\n"
                f"- manual-runbook: `{int(tiers.get('manual-runbook', 0))}`"
            )
            body = (
                "## What This PR Changes\n"
                f"- Category: `{category}`\n"
                f"- Generated Terraform files: `{cat.get('checks', 0)}` checks\n"
                f"- Path: `{path}`\n\n"
                "## Execution Tiers\n"
                f"{tier_lines}\n\n"
                "## Priority (Top 5)\n"
                f"{top5}\n\n"
                "## Merge Impact\n"
                "- This will trigger `Security Pipeline - 03 Apply Merged Generated Terraform Remediation`.\n"
                "- Applied changes are limited to security-remediation attributes for this category.\n\n"
                "## How To Verify\n"
                "1. Merge this PR.\n"
                "2. Confirm apply workflow succeeds.\n"
                "3. Confirm `Security Pipeline - 04 Verify FAIL Reduction` shows FAIL reduction.\n\n"
                "## Remaining Manual Runbook\n"
                f"{manual}\n"
            )

            p = subprocess.run(
                [
                    "gh",
                    "pr",
                    "create",
                    "--base",
                    "main",
                    "--head",
                    branch,
                    "--title",
                    message,
                    "--body",
                    body,
                ],
                capture_output=True,
                text=True,
            )
            if p.returncode != 0:
                err = (p.stderr or "").strip()
                if "not permitted to create or approve pull requests" in err.lower():
                    print(f"warn: PR create skipped by repo policy for {category}")
                    continue
                raise RuntimeError(f"cmd failed: gh pr create\n{err}")

    run(["git", "checkout", "main"], check=False)


if __name__ == "__main__":
    main()
