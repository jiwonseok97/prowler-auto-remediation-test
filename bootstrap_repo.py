#!/usr/bin/env python3
"""Interactive bootstrap for prowler-auto-remediation-test PoC repo."""

from __future__ import annotations

import shutil
import subprocess
import urllib.error
import urllib.request
import json
from pathlib import Path


def ask_bool(prompt: str, default: bool = False) -> bool:
    raw = input(prompt).strip().lower()
    if not raw:
        return default
    return raw in {"y", "yes", "true", "1"}


def run(cmd: list[str], cwd: Path | None = None) -> None:
    subprocess.run(cmd, check=True, cwd=str(cwd) if cwd else None)


def github_api(token: str, method: str, url: str, payload: dict | None = None) -> dict:
    data = None
    if payload is not None:
        data = json.dumps(payload).encode("utf-8")
    req = urllib.request.Request(
        url=url,
        method=method,
        data=data,
        headers={
            "Authorization": f"Bearer {token}",
            "Accept": "application/vnd.github+json",
            "X-GitHub-Api-Version": "2022-11-28",
            "Content-Type": "application/json",
            "User-Agent": "prowler-auto-remediation-bootstrap",
        },
    )
    try:
        with urllib.request.urlopen(req) as resp:
            raw = resp.read().decode("utf-8")
            return json.loads(raw) if raw else {}
    except urllib.error.HTTPError as e:
        details = e.read().decode("utf-8", errors="ignore")
        raise RuntimeError(f"GitHub API error {e.code} at {url}: {details}") from e


def create_github_repo(token: str, owner_name: str, private: bool, repo_name: str) -> str:
    me = github_api(token, "GET", "https://api.github.com/user")
    login = str(me.get("login", "")).strip()
    target = owner_name.strip()

    payload = {
        "name": repo_name,
        "private": private,
        "auto_init": False,
        "description": "Terraform + Prowler + AI remediation PoC",
    }

    if not target or target == login:
        repo = github_api(token, "POST", "https://api.github.com/user/repos", payload)
        return str(repo.get("clone_url", ""))

    try:
        repo = github_api(token, "POST", f"https://api.github.com/orgs/{target}/repos", payload)
        return str(repo.get("clone_url", ""))
    except RuntimeError as e:
        raise RuntimeError(
            f"Cannot create repo under '{target}'. Use your login '{login}' or an org where token has repo permission. {e}"
        ) from e


def main() -> int:
    repo_name = "prowler-auto-remediation-test"

    github_token = input("GitHub Personal Access Token: ").strip()
    github_owner = input("GitHub account/org name: ").strip()
    private_repo = ask_bool("Private repo? (yes/no): ", default=True)

    aws_access_key = input("AWS_ACCESS_KEY_ID: ").strip()
    aws_secret_key = input("AWS_SECRET_ACCESS_KEY: ").strip()
    aws_region = input("AWS_DEFAULT_REGION: ").strip()
    multi_region = ask_bool("Multi-region environment? (yes/no): ", default=True)

    ai_model = input("AI model (ex: gpt-4.1, bedrock-claude-3): ").strip()
    ai_api_key = input("AI API key: ").strip()

    base = Path(__file__).resolve().parent
    if not base.exists():
        raise SystemExit(f"Missing scaffold directory: {base}")

    tfvars = base / "terraform" / "test_infra" / "terraform.tfvars"
    tfvars.write_text(
        "\n".join(
            [
                f'aws_region   = "{aws_region}"',
                f"multi_region = {str(multi_region).lower()}",
            ]
        )
        + "\n",
        encoding="utf-8",
    )

    env_example = base / ".env.example"
    env_example.write_text(
        "\n".join(
            [
                "AWS_ACCESS_KEY_ID=<set-in-github-secret>",
                "AWS_SECRET_ACCESS_KEY=<set-in-github-secret>",
                f"AWS_DEFAULT_REGION={aws_region}",
                f"AI_MODEL={ai_model}",
                "AI_API_KEY=<set-in-github-secret>",
            ]
        )
        + "\n",
        encoding="utf-8",
    )

    clone_url = create_github_repo(github_token, github_owner, private_repo, repo_name)

    git_dir = base / ".git"
    if git_dir.exists():
        shutil.rmtree(git_dir)

    run(["git", "init", "-b", "main"], cwd=base)
    run(["git", "add", "."], cwd=base)
    run(["git", "commit", "-m", "chore: initial PoC scaffold"], cwd=base)
    run(["git", "remote", "add", "origin", clone_url], cwd=base)
    run(["git", "push", "-u", "origin", "main"], cwd=base)

    print("\nBootstrap complete")
    print(f"Repo: {repo_name}")
    print("Inputs received (set as GitHub secrets manually):")
    print(f"- AWS_ACCESS_KEY_ID: {'set' if aws_access_key else 'missing'}")
    print(f"- AWS_SECRET_ACCESS_KEY: {'set' if aws_secret_key else 'missing'}")
    print(f"- AWS_DEFAULT_REGION: {aws_region}")
    print(f"- AI_MODEL: {ai_model}")
    print(f"- AI_API_KEY: {'set' if ai_api_key else 'missing'}")
    print("Remember to set GitHub Actions secrets in the new repository.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
