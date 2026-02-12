#!/usr/bin/env bash
set -euo pipefail

# Simple micro-benchmark for src/slf4.sh log() function
# Usage: tool/bench_logging.sh [ITERATIONS]

ITER=${1:-1000}
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Source logger (will call sl_init when sourced)
# Temporarily disable nounset to avoid errors from the sourced file checking
set +u
source "${REPO_ROOT}/src/slf4.sh"
set -u

# Short helper for ns timing
time_ns() { date +%s%N; }

run_loop() {
  local name="$1"; shift
  local i start end elapsed avg_ns avg_ms
  start=$(time_ns)
  for ((i=0;i<ITER;i++)); do
    "$@"
  done
  end=$(time_ns)
  elapsed=$((end - start))
  avg_ns=$((elapsed / ITER))
  avg_ms=$(awk -v n="$avg_ns" 'BEGIN{printf "%.6f", n/1e6}')
  printf "%s: total=%d ns avg=%s ms/op\n" "$name" "$elapsed" "$avg_ms"
}

# Tests
printf "Benchmarking log() with %d iterations\n" "$ITER"

# 1) direct call with a short message
run_loop "direct_short" logInfo "x"

# 2) direct call with a longer message
LONGMSG=$(printf 'x%.0s' {1..200})
run_loop "direct_long(200)" logInfo "$LONGMSG"

# 3) piped input version (each iteration spawns a pipeline)
# Run piped tests in the current shell so logInfo function is available
run_pipe_test() {
  local name="$1" msg="$2" i start end elapsed avg_ns avg_ms
  start=$(time_ns)
  for ((i=0;i<ITER;i++)); do
    printf '%s\n' "$msg" | logInfo
  done
  end=$(time_ns)
  elapsed=$((end - start))
  avg_ns=$((elapsed / ITER))
  avg_ms=$(awk -v n="$avg_ns" 'BEGIN{printf "%.6f", n/1e6}')
  printf "%s: total=%d ns avg=%s ms/op\n" "$name" "$elapsed" "$avg_ms"
}

run_pipe_test "piped_short" "x"
run_pipe_test "piped_long(200)" "$LONGMSG"

printf "Done. Log file: %s\n" "${SL_LOGFILE:-<unknown>}"
