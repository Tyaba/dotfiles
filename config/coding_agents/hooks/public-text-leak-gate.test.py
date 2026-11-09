"""public-text-leak-gate.py の動作テスト。

ダミーのユーザー名・gcloud 構成・denylist と一時 git リポジトリで検査する。
非公開リポジトリでの個人識別子と秘密の扱い、公開設定の取得条件も検査する。
実行: python3 -I config/coding_agents/hooks/public-text-leak-gate.test.py
"""

import json, os, subprocess, sys, tempfile
from pathlib import Path

HOOK = str(Path(__file__).with_name("public-text-leak-gate.py"))
tmpdir = tempfile.TemporaryDirectory(dir=Path.cwd())
tmp = Path(tmpdir.name)
fake_bin = tmp / "bin"
fake_bin.mkdir()
fake_gh_log = tmp / "gh.log"
fake_gh = fake_bin / "gh"
fake_gh.write_text('''#!/bin/sh
printf '%s\\n' "$*" >> "$FAKE_GH_LOG"
if [ "${FAKE_GH_FAIL:-}" = 1 ]; then exit 1; fi
echo "${FAKE_GH_VISIBILITY:-PUBLIC}"
''')
fake_gh.chmod(0o755)
gc = tmp / "gcloud" / "configurations"
gc.mkdir(parents=True)
(gc / "config_good").write_text("[core]\naccount = leakuser@corp.example\nproject = my-secret-proj-123\n")
env = dict(os.environ, USER="leakuser", CLOUDSDK_CONFIG=str(tmp / "gcloud"),
           LEAK_GATE_DENYLIST=str(tmp / "deny"), DOTFILES_GCLOUD_CONFIGURATION="good",
           PATH=f"{fake_bin}{os.pathsep}{os.environ.get('PATH', '')}", FAKE_GH_LOG=str(fake_gh_log))
env.pop("FAKE_GH_FAIL", None); env.pop("FAKE_GH_VISIBILITY", None)
(tmp / "body.md").write_text("ref /Users/leakuser/.cursor\n")
(tmp / "deny").write_text("# comment\nInternalCodename\n")

remote = tmp / "remote.git"
repo = tmp / "repo"
def g(*a, cwd=repo):
    subprocess.run(["git", *a], cwd=cwd, check=True, capture_output=True, env=env)
subprocess.run(["git", "init", "-q", "--bare", str(remote)], check=True)
subprocess.run(["git", "init", "-q", str(repo)], check=True)
g("config", "user.email", "pub@example.com"); g("config", "user.name", "pub")
(repo / "a.txt").write_text("hello\n"); g("add", "."); g("commit", "-qm", "init")
g("remote", "add", "origin", str(remote)); g("push", "-q", "origin", "HEAD:main")
g("fetch", "-q", "origin")

def run(cmd, cwd=repo, extra_env=None):
    r = subprocess.run([sys.executable, HOOK], input=json.dumps(
        {"tool_name": "Bash", "tool_input": {"command": cmd}, "cwd": str(cwd)}),
        capture_output=True, text=True, env=dict(env, **(extra_env or {})))
    assert r.returncode == 0, r.stderr
    return "deny" if '"deny"' in r.stdout else "pass"

cases = []
def case(name, cmd, want, cwd=repo, extra_env=None, gh_not_called=False):
    if gh_not_called:
        fake_gh_log.unlink(missing_ok=True)
    got = run(cmd, cwd, extra_env)
    if gh_not_called and fake_gh_log.exists() and fake_gh_log.read_text():
        got += " (gh called)"
    cases.append((got == want, name, want, got))

# gh
case("gh body heredoc w/ home path", "gh pr create --title t --body-file - <<'EOF'\nsee /Users/leakuser/x\nEOF", "deny")
case("gh body clean, cd path local", "cd /Users/leakuser/repo && gh pr create --title t --body-file - <<'EOF'\nclean\nEOF", "pass")
case("gh --title leak", 'gh pr create --title "fix for leakuser" --body ok', "deny")
case("gh --body= leak", 'gh issue comment 1 --body=project:my-secret-proj-123', "deny")
case("gh body-file leak", f"gh pr edit 1 --body-file {tmp}/body.md", "deny")
case("gh -F file leak", f"gh pr create -F {tmp}/body.md -t x", "deny")
case("gh api field", "gh api repos/a/b/issues -f body='mail leakuser@corp.example'", "deny")
case("gh api field file", f"gh api x -F body=@{tmp}/body.md", "deny")
case("denylist", 'gh pr comment 1 -b "about internalcodename"', "deny")
case("secret token", 'gh pr comment 1 -b "ghp_' + "a" * 36 + '"', "deny")
case("substring not word", 'gh pr comment 1 -b "xleakuserx"', "pass")
case("gh view not publish", "gh pr view 1", "pass")
case("non git cmd", "echo leakuser", "pass")
case("here-string not heredoc", 'gh pr comment 1 -b ok <<<"x"', "pass")
case("-d draft not eating file", f"gh pr create -d --body-file {tmp}/body.md", "deny")
case("multi-line command, 2nd segment", "echo hi\ngh pr comment 1 -b leakuser", "deny")
case("private project", 'gh pr create --body "my-secret-proj-123"', "pass", extra_env={"FAKE_GH_VISIBILITY": "PRIVATE"})
case("internal project", 'gh pr create --body "my-secret-proj-123"', "pass", extra_env={"FAKE_GH_VISIBILITY": "INTERNAL"})
case("public project", 'gh pr create --body "my-secret-proj-123"', "deny", extra_env={"FAKE_GH_VISIBILITY": "PUBLIC"})
case("visibility lookup failure", 'gh pr create --body "my-secret-proj-123"', "deny", extra_env={"FAKE_GH_FAIL": "1"})
case("private secret token", 'gh pr create --body "ghp_' + "a" * 36 + '"', "deny", extra_env={"FAKE_GH_VISIBILITY": "PRIVATE"})
case("clean body skips gh", 'gh pr create --body "clean"', "pass", gh_not_called=True)
# git commit
case("commit -m leak", 'git commit -m "path /home/leakuser"', "deny")
case("commit -am leak", 'git commit -am "leakuser"', "deny")
case("commit -F file", f"git commit -F {tmp}/body.md", "deny")
case("commit heredoc", "git commit -F - <<'EOF'\nby leakuser\nEOF", "deny")
case("commit clean", 'git commit -m "clean"', "pass")
(repo / "b.txt").write_text("token for my-secret-proj-123\n")
case("commit unstaged leak not -a", 'git commit -m clean', "pass")
g("add", "b.txt")
case("commit staged leak", 'git commit -m clean', "deny")
case("commit staged leak via -C", f'git -C {repo} commit -m clean', "deny", cwd=tmp)
g("commit", "-qm", "add b")
# git push
case("push unpushed diff leak", "git push origin HEAD", "deny")
case("push via cd", f"cd {repo} && git push -u origin HEAD", "deny", cwd=tmp)
g("reset", "-q", "--hard", "origin/main")
(repo / "c.txt").write_text("fine\n"); g("add", "."); g("commit", "-qm", "clean")
case("push clean", "git push origin HEAD", "pass")
g("commit", "-q", "--allow-empty", "-m", "msg mentions leakuser")
case("push msg leak", "git push", "deny")
case("private push msg leak", "git push", "pass", extra_env={"FAKE_GH_VISIBILITY": "PRIVATE"})
g("reset", "-q", "--hard", "HEAD~1")
subprocess.run(["git", "-c", "user.email=leakuser@corp.example", "commit", "-q", "--allow-empty", "-m", "x"], cwd=repo, check=True, env=env)
case("push author email leak", "git push origin feat:feat", "pass")  # src branch 'feat' doesn't exist
case("push author email leak HEAD", "git push origin HEAD:feat", "deny")
case("tag -m leak", "git tag -a v1 -m leakuser", "deny")

fails = 0
for ok, name, want, got in cases:
    if not ok:
        fails += 1
    print(("OK  " if ok else "FAIL"), name, f"want={want} got={got}")
print(f"{len(cases) - fails}/{len(cases)} passed")
sys.exit(1 if fails else 0)
