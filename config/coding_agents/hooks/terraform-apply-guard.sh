#!/bin/bash
# PreToolUse hook: gate terraform destructive operations (apply / destroy).
#
# Multi-layer gate:
#   1. Environment: cwd path containing /prd/ (or workspace = prd|production) → deny
#   2. Branch: current git branch is main|master|release/* → deny
#   3. Plan content: stateful GCP resource destroy/replace in plan → deny
# Otherwise allow.
#
# Also strips leading `echo yes | ...` / `yes | ...` wrappers so they cannot
# be used to bypass the gate.

set -euo pipefail

input=$(cat)
COMMAND=$(echo "$input" | jq -r '.tool_input.command // empty')

if [ -z "$COMMAND" ]; then
  exit 0
fi

# Strip leading `echo (y|yes) |` and `yes |` so wrappers can't bypass the gate
COMMAND=$(echo "$COMMAND" | sed -E 's/^[[:space:]]*echo[[:space:]]+(y|yes)[[:space:]]*\|[[:space:]]*//')
COMMAND=$(echo "$COMMAND" | sed -E 's/^[[:space:]]*yes[[:space:]]*\|[[:space:]]*//')

# ── Parse: terraform binary, -chdir, subcommand, remaining args ──

tf_bin=""
chdir_opt=""
remaining_args=()

read -ra tokens <<< "$COMMAND"
i=0
while [ $i -lt ${#tokens[@]} ]; do
  tok="${tokens[$i]}"
  case "$tok" in
    terraform|*/terraform)
      tf_bin="$tok"
      ;;
    -chdir=*)
      chdir_opt="$tok"
      ;;
    -chdir)
      i=$((i + 1))
      chdir_opt="-chdir=${tokens[$i]}"
      ;;
    *)
      remaining_args+=("$tok")
      ;;
  esac
  i=$((i + 1))
done

if [ -z "$tf_bin" ]; then
  exit 0
fi

subcommand=""
sub_args=()
found_sub=false
for arg in "${remaining_args[@]}"; do
  if [ "$found_sub" = false ]; then
    case "$arg" in
      apply|destroy)
        subcommand="$arg"
        found_sub=true
        ;;
    esac
  else
    case "$arg" in
      -auto-approve|--auto-approve) ;;
      *) sub_args+=("$arg") ;;
    esac
  fi
done

if [ -z "$subcommand" ]; then
  exit 0
fi

# ── Helpers ──

emit_deny() {
  jq -n --arg reason "$1" '{
    hookSpecificOutput: {
      hookEventName: "PreToolUse",
      permissionDecision: "deny",
      permissionDecisionReason: $reason
    }
  }'
  exit 0
}

emit_allow() {
  jq -n --arg reason "$1" '{
    hookSpecificOutput: {
      hookEventName: "PreToolUse",
      permissionDecision: "allow",
      permissionDecisionReason: $reason
    }
  }'
  exit 0
}

# Determine the working directory terraform will operate in
tf_cwd="$PWD"
if [ -n "$chdir_opt" ]; then
  tf_cwd_path="${chdir_opt#-chdir=}"
  case "$tf_cwd_path" in
    /*) tf_cwd="$tf_cwd_path" ;;
    *) tf_cwd="$PWD/$tf_cwd_path" ;;
  esac
fi

# ── Layer 1: environment gate (path + terraform workspace) ──

env_label="unknown"
case "$tf_cwd" in
  */prd/*|*/prd|*/production/*|*/production) env_label="prd" ;;
  */stg/*|*/stg|*/staging/*|*/staging) env_label="stg" ;;
  */dev/*|*/dev|*/development/*|*/development) env_label="dev" ;;
esac

workspace=""
workspace=$(cd "$tf_cwd" 2>/dev/null && terraform workspace show 2>/dev/null || true)
case "$workspace" in
  prd|production) env_label="prd" ;;
esac

if [ "$env_label" = "prd" ]; then
  emit_deny "Blocked: terraform $subcommand on prd environment (cwd=$tf_cwd, workspace=${workspace:-unknown}). Production changes require manual workflow with explicit approval."
fi

# ── Layer 2: branch gate ──

branch=$(cd "$tf_cwd" 2>/dev/null && git branch --show-current 2>/dev/null || true)
case "$branch" in
  main|master)
    emit_deny "Blocked: terraform $subcommand on $branch branch (cwd=$tf_cwd). Create a feature branch and merge via PR."
    ;;
  release/*)
    emit_deny "Blocked: terraform $subcommand on release branch $branch (cwd=$tf_cwd)."
    ;;
esac

# ── Layer 3: plan content inspection ──

plan_cmd=("$tf_bin")
[ -n "$chdir_opt" ] && plan_cmd+=("$chdir_opt")
if [ "$subcommand" = "destroy" ]; then
  plan_cmd+=(plan -destroy -json -input=false)
else
  plan_cmd+=(plan -json -input=false)
fi
plan_cmd+=("${sub_args[@]+"${sub_args[@]}"}")

stderr_file=$(mktemp -t tf-guard-stderr.XXXXXX)
trap 'rm -f "$stderr_file"' EXIT

if ! plan_output=$("${plan_cmd[@]}" 2>"$stderr_file"); then
  stderr=$(cat "$stderr_file" 2>/dev/null || true)
  emit_deny "terraform plan failed. Blocking $subcommand for safety.$([ -n "$stderr" ] && echo " stderr: $stderr")"
fi

STATEFUL_PATTERNS=(
  "google_bigquery_"
  "google_storage_bucket"
  "google_sql_"
  "google_compute_instance"
  "google_redis_instance"
  "google_spanner_"
  "google_bigtable_"
  "google_filestore_instance"
)
pattern_regex=$(IFS="|"; echo "${STATEFUL_PATTERNS[*]}")

violations=$(echo "$plan_output" \
  | jq -r '
    select(.type == "planned_change")
    | .change
    | select(.resource)
    | .resource.resource_type as $type
    | .resource.resource_name as $name
    | .action as $action
    | select($action == "delete" or $action == "replace")
    | "\($type).\($name) (\($action))"
  ' 2>/dev/null \
  | grep -E "$pattern_regex" || true)

if [ -n "$violations" ]; then
  reason="Blocked: stateful resource destroy/replace detected in terraform $subcommand plan:"
  while IFS= read -r line; do
    reason="$reason"$'\n'"- $line"
  done <<< "$violations"
  emit_deny "$reason"
fi

emit_allow "terraform $subcommand allowed: env=$env_label, branch=${branch:-none}, no stateful destroy/replace"
