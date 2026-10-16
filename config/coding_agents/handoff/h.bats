#!/usr/bin/env bats

setup() {
  bats_require_minimum_version 1.5.0
  H="$BATS_TEST_DIRNAME/h.sh"
  TEST_ROOT=$(mktemp -d)
  export XDG_CACHE_HOME="$TEST_ROOT/cache"
  export GIT_CONFIG_NOSYSTEM=1
  export GIT_CONFIG_GLOBAL=/dev/null
  REPO="$TEST_ROOT/repo with spaces"
  git -c init.defaultBranch=main init -q "$REPO"
  cd "$REPO"
}

teardown() {
  cd "$BATS_TEST_DIRNAME"
  rm -rf "$TEST_ROOT"
}

@test "--path creates only the directory and hashes the key without a newline" {
  run "$H" --path
  [ "$status" -eq 0 ]
  local digest
  digest=$(printf '%s' "$(git rev-parse --show-toplevel)" | shasum -a 256)
  [ "$output" = "$XDG_CACHE_HOME/claude-handoff/${digest:0:16}.sh" ]
  [ -d "${output%/*}" ]
  [ ! -e "$output" ]
}

@test "--path is stable within a repository" {
  local staged
  staged=$("$H" --path)
  mkdir -p nested/child
  cd nested/child
  run "$H" --path
  [ "$status" -eq 0 ]
  [ "$output" = "$staged" ]
}

@test "--path differs between repositories" {
  local staged
  staged=$("$H" --path)
  git -c init.defaultBranch=main init -q "$TEST_ROOT/other"
  cd "$TEST_ROOT/other"
  run "$H" --path
  [ "$status" -eq 0 ]
  [ "$output" != "$staged" ]
}

@test "--path differs between a repository and its worktree" {
  local staged
  staged=$("$H" --path)
  git -c user.name=Test -c user.email=test@example.com -c commit.gpgsign=false \
    commit --allow-empty -qm initial
  git worktree add -q --detach "$TEST_ROOT/worktree" HEAD
  cd "$TEST_ROOT/worktree"
  run "$H" --path
  [ "$status" -eq 0 ]
  [ "$output" != "$staged" ]
}

@test "outside git --path uses PWD as the key" {
  mkdir "$TEST_ROOT/plain"
  cd "$TEST_ROOT/plain"
  local digest
  digest=$(printf '%s' "$PWD" | shasum -a 256)
  run "$H" --path
  [ "$status" -eq 0 ]
  [ "$output" = "$XDG_CACHE_HOME/claude-handoff/${digest:0:16}.sh" ]
}

@test "--path falls back to HOME when XDG_CACHE_HOME is unset" {
  export HOME="$TEST_ROOT/home"
  unset XDG_CACHE_HOME
  run "$H" --path
  [ "$status" -eq 0 ]
  [[ "$output" == "$HOME/.cache/claude-handoff/"* ]]
  [ -d "${output%/*}" ]
  [ ! -e "$output" ]
}

@test "shasum fallback produces the same path as sha256sum" {
  local staged tool
  staged=$("$H" --path)
  mkdir "$TEST_ROOT/bin"
  for tool in bash git mkdir shasum; do
    ln -s "$(command -v "$tool")" "$TEST_ROOT/bin/$tool"
  done
  PATH="$TEST_ROOT/bin" run "$H" --path
  [ "$status" -eq 0 ]
  [ "$output" = "$staged" ]
}

@test "nothing staged exits 1 with a message only on stderr" {
  run --separate-stderr "$H"
  [ "$status" -eq 1 ]
  [ -z "$output" ]
  [ "$stderr" = "h: nothing staged for $(git rev-parse --show-toplevel)" ]
}

@test "run prints the command, consumes it before execution, and keeps cwd without a TTY" {
  export STAGED_FILE OUTPUT_FILE="$TEST_ROOT/executed-in"
  STAGED_FILE=$("$H" --path)
  cat > "$STAGED_FILE" <<'SCRIPT'
if [ -e "$STAGED_FILE" ]; then exit 99; fi
pwd > "$OUTPUT_FILE"
printf '%s\n' 'command output'
SCRIPT
  cp "$STAGED_FILE" "$TEST_ROOT/expected.sh"
  mkdir nested
  cd nested
  run "$H" < /dev/null
  [ "$status" -eq 0 ]
  [ "${lines[0]}" = "h: running staged command for $(git rev-parse --show-toplevel):" ]
  [[ "$output" == *"$(cat "$TEST_ROOT/expected.sh")"$'\n\n---\ncommand output' ]]
  [ "$(cat "$OUTPUT_FILE")" = "$PWD" ]
  [ ! -e "$STAGED_FILE" ]
  cmp "$TEST_ROOT/expected.sh" "${STAGED_FILE%.sh}.last.sh"
  run "$H"
  [ "$status" -eq 1 ]
}

@test "a failed command propagates its exit code and remains consumed" {
  local staged
  staged=$("$H" --path)
  printf 'exit 37\n' > "$staged"
  run "$H"
  [ "$status" -eq 37 ]
  [ ! -e "$staged" ]
  [ -f "${staged%.sh}.last.sh" ]
  run "$H"
  [ "$status" -eq 1 ]
}

@test "--show prints the staged bytes without executing or consuming" {
  local staged
  staged=$("$H" --path)
  printf 'exit 37\n\nprintf untouched' > "$staged"
  "$H" --show > "$TEST_ROOT/shown"
  cmp "$staged" "$TEST_ROOT/shown"
  [ ! -e "${staged%.sh}.last.sh" ]
}

@test "--show with nothing staged exits 1 with a message on stderr" {
  run --separate-stderr "$H" --show
  [ "$status" -eq 1 ]
  [ -z "$output" ]
  [ "$stderr" = "h: nothing staged for $(git rev-parse --show-toplevel)" ]
}

@test "--help prints usage on stdout and exits 0" {
  run --separate-stderr "$H" --help
  [ "$status" -eq 0 ]
  [[ "$output" == 'Usage: h '* ]]
  [ -z "$stderr" ]
  [ ! -e "$XDG_CACHE_HOME" ]
}

@test "unknown options and extra arguments print usage on stderr and exit 2" {
  local argument
  for argument in --unknown unexpected; do
    run --separate-stderr "$H" "$argument"
    [ "$status" -eq 2 ]
    [ -z "$output" ]
    [[ "$stderr" == 'Usage: h '* ]]
  done
  run --separate-stderr "$H" --path extra
  [ "$status" -eq 2 ]
  [ -z "$output" ]
  [[ "$stderr" == 'Usage: h '* ]]
}
