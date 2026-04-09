#!/bin/bash
# PreToolUse hook: guard terraform apply by running plan first.
# Denies apply when stateful GCP resources would be replaced or destroyed.
# Used by Claude Code settings.json PreToolUse hook with matcher "Bash"
# and if condition "Bash(terraform :* apply :*)".

set -euo pipefail

input=$(cat)
COMMAND=$(echo "$input" | jq -r '.tool_input.command // empty')

if [ -z "$COMMAND" ]; then
  exit 0
fi

# ── Extract terraform binary and global options ──

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

# ── Must be an apply subcommand ──

subcommand=""
apply_args=()
found_apply=false

for arg in "${remaining_args[@]}"; do
  if [ "$found_apply" = false ]; then
    if [ "$arg" = "apply" ]; then
      found_apply=true
      subcommand="apply"
    fi
  else
    case "$arg" in
      -auto-approve|--auto-approve) ;;
      *) apply_args+=("$arg") ;;
    esac
  fi
done

if [ "$subcommand" != "apply" ]; then
  exit 0
fi

# ── Build and run the equivalent plan -json command ──

plan_cmd=("$tf_bin")
[ -n "$chdir_opt" ] && plan_cmd+=("$chdir_opt")
plan_cmd+=(plan -json -input=false)
plan_cmd+=("${apply_args[@]}")

plan_output=$("${plan_cmd[@]}" 2>/tmp/tf-apply-guard-stderr) || {
  stderr=$(cat /tmp/tf-apply-guard-stderr 2>/dev/null || true)
  echo "terraform plan failed. Blocking apply for safety." >&2
  [ -n "$stderr" ] && echo "$stderr" >&2
  exit 2
}

# ── Parse resource_changes for stateful resource destroy/replace ──

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
  reason="Blocked: stateful resource destroy/replace detected in terraform plan:"
  while IFS= read -r line; do
    reason="$reason\n- $line"
  done <<< "$violations"

  jq -n --arg reason "$reason" '{
    hookSpecificOutput: {
      hookEventName: "PreToolUse",
      permissionDecision: "deny",
      permissionDecisionReason: $reason
    }
  }'
else
  jq -n '{
    hookSpecificOutput: {
      hookEventName: "PreToolUse",
      permissionDecision: "allow",
      permissionDecisionReason: "terraform plan shows no stateful resource destroy/replace"
    }
  }'
fi
