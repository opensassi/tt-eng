#!/usr/bin/env bash
set -euo pipefail

# env-check.sh
# Verifies toolchain readiness for the TT-Metalium LLM agent validation pipeline.
# Outputs JSON to stdout and writes to results/env-check.json.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
RESULTS_DIR="$PROJECT_ROOT/results"
mkdir -p "$RESULTS_DIR"

# Initialize result
result=$(cat <<'JSONEOF'
{
  "timestamp": "",
  "os": "",
  "distro": "",
  "tools": {},
  "paths": {},
  "errors": [],
  "all_ready": false
}
JSONEOF
)

timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
result=$(echo "$result" | jq --arg ts "$timestamp" '.timestamp = $ts')

# OS detection
os=""
distro=""
case "$(uname -s)" in
  Linux)
    os="linux"
    if command -v lsb_release &>/dev/null; then
      distro=$(lsb_release -ds 2>/dev/null || echo "unknown")
    elif [ -f /etc/os-release ]; then
      distro=$(grep -oP '(?<=^PRETTY_NAME=").*(?=")' /etc/os-release 2>/dev/null || echo "unknown")
    else
      distro="unknown"
    fi
    ;;
  Darwin)
    os="darwin"
    distro="macOS $(sw_vers -productVersion 2>/dev/null || echo 'unknown')"
    ;;
  *)
    os="unknown"
    distro="unknown"
    ;;
esac
result=$(echo "$result" | jq --arg os "$os" --arg distro "$distro" '.os = $os | .distro = $distro')

# Tool checks
tools=(
  "git:git --version"
  "g++:g++ --version"
  "cmake:cmake --version"
  "make:make --version"
  "python3:python3 --version"
  "perf:perf --version"
  "jq:jq --version"
  "nasm:nasm --version"
  "gdb:gdb --version"
  "objdump:objdump --version"
  "flamegraph-pl:flamegraph.pl --version 2>/dev/null || echo 'not found'"
  "bzip2:bzip2 --version"
  "curl:curl --version"
)

for tool_entry in "${tools[@]}"; do
  tool_name="${tool_entry%%:*}"
  tool_cmd="${tool_entry#*:}"
  # Handle special case: commands with embedded redirects
  if [[ "$tool_cmd" == *">"* ]]; then
    if $tool_cmd &>/dev/null; then
      version=$(bash -c "$tool_cmd" 2>&1 | head -1)
      result=$(echo "$result" | jq --arg name "$tool_name" --arg ver "$version" '.tools[$name] = $ver')
    else
      result=$(echo "$result" | jq --arg name "$tool_name" '.tools[$name] = "not_found"')
      result=$(echo "$result" | jq --arg name "$tool_name" '.errors += [$name + ": not found"]')
    fi
  elif command -v "${tool_cmd%% *}" &>/dev/null 2>&1; then
    version=$($tool_cmd 2>&1 | head -1)
    result=$(echo "$result" | jq --arg name "$tool_name" --arg ver "$version" '.tools[$name] = $ver')
  else
    result=$(echo "$result" | jq --arg name "$tool_name" '.tools[$name] = "not_found"')
    result=$(echo "$result" | jq --arg name "$tool_name" '.errors += [$name + ": not found"]')
  fi
done

# Path checks
paths_to_check=(
  "tt-metal:$PROJECT_ROOT/external/tt-metal/tt_metal"
  "ttsim:$PROJECT_ROOT/external/ttsim"
  "soc-descriptor:$PROJECT_ROOT/external/tt-metal/tt_metal/soc_descriptors/blackhole_140_arch.yaml"
  "scripts-flamegraph:$PROJECT_ROOT/scripts/FlameGraph"
  "config:$PROJECT_ROOT/config/stages.json"
)

for path_entry in "${paths_to_check[@]}"; do
  path_name="${path_entry%%:*}"
  path_val="${path_entry#*:}"
  if [ -e "$path_val" ]; then
    result=$(echo "$result" | jq --arg name "$path_name" --arg p "$path_val" '.paths[$name] = $p')
  else
    result=$(echo "$result" | jq --arg name "$path_name" --arg p "$path_val" '.paths[$name] = "missing"')
    result=$(echo "$result" | jq --arg name "$path_name" --arg p "$path_val" '.errors += [$name + ": missing at " + $p]')
  fi
done

# Check environment variables
env_vars=("TT_METAL_HOME" "TT_METAL_SIMULATOR")
for var in "${env_vars[@]}"; do
  if [ -z "${!var:-}" ]; then
    result=$(echo "$result" | jq --arg var "$var" '.errors += [$var + ": not set"]')
  fi
done

# Final verdict
errors_count=$(echo "$result" | jq '.errors | length')
if [ "$errors_count" -eq 0 ]; then
  result=$(echo "$result" | jq '.all_ready = true')
fi

echo "$result" | tee "$RESULTS_DIR/env-check.json"
