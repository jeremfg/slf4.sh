# shellcheck shell=bash
# SPDX-License-Identifier: MIT
#
# Source this into any shell script you wish to add logging support.
# Inspired From: https://serverfault.com/a/103569
#

if [[ -z ${GUARD_SLF4SH_SH} ]]; then
  GUARD_SLF4SH_SH=1
else
  return 0
fi

# shellcheck disable=SC2034  # Unused variables left documentation purpose
SLF4SH_VERSION="1.2.0"

# LEVEL_ALL appears unused. Verify use (or export if used externally).
# LEVEL_OFF appears unused. Verify use (or export if used externally).
# shellcheck disable=2034

LEVEL_ALL=0   # Enable all possible logs.
LEVEL_TEST=1  # Only used by developers to temporarily add logs that should never get commited.
LEVEL_TRACE=2 # Low level tracing of very detailed specifc information.
LEVEL_DEBUG=3 # Might allow to investigate and resolve a bug.
LEVEL_INFO=4  # Default level. High level indications of the paths the code took.
LEVEL_WARN=5  # Unusual behavior that don't cause an issue to the current execution.
LEVEL_ERROR=6 # A recoverable error occured. The program is still executing properly but the user is not getting the desired outcome.
LEVEL_FATAL=7 # Unrecoverable error. Program is exiting immediately for safety as it wasn't designed to continue after this.
# shellcheck disable=SC2034  # Unused variables left for readability
LEVEL_OFF=8 # Turns of all logs

# If no level is configured, start at INFO
if [[ -z "${LOG_LEVEL}" ]]; then
  LOG_LEVEL=${LEVEL_INFO}
fi

# By default do not print logs on the console but only in the log file
if [[ -z "${LOG_CONSOLE}" ]]; then
  LOG_CONSOLE=0
fi

# Set the log level
#
# @parms[in] #1: The logging level to be used from now on, using one of the LEVEL_* values
logSetLevel() {
  LOG_LEVEL="$1"
}

logFatal() {
  if [[ "${LOG_LEVEL}" -le ${LEVEL_FATAL} ]]; then
    log "FATAL" "$@"
  fi
  exit 1
}

logError() {
  if [[ "${LOG_LEVEL}" -le ${LEVEL_ERROR} ]]; then
    log "ERROR" "$@"
  fi
}

logWarn() {
  if [[ "${LOG_LEVEL}" -le ${LEVEL_WARN} ]]; then
    log " WARN" "$@"
  fi
}

logInfo() {
  if [[ "${LOG_LEVEL}" -le ${LEVEL_INFO} ]]; then
    log " INFO" "$@"
  fi
}

logDebug() {
  if [[ "${LOG_LEVEL}" -le ${LEVEL_DEBUG} ]]; then
    log "DEBUG" "$@"
  fi
}

logTrace() {
  if [[ "${LOG_LEVEL}" -le ${LEVEL_TRACE} ]]; then
    log "TRACE" "$@"
  fi
}

logTest() {
  if [[ "${LOG_LEVEL}" -le ${LEVEL_TEST} ]]; then
    log " TEST" "$@"
  fi
}

log() {
  local level
  level="${1}"
  shift

  local date time file line location prefix pid message caller_info resolved

  date=$(date +%F)
  time=$(date +%H:%M:%S)
  pid="$$"

  # Get caller file:line using helper (capture stdout)
  caller_info=$(__slf4_get_caller 2>/dev/null || true)
  if [[ -n "${caller_info}" && "${caller_info}" == *:* ]]; then
    file=${caller_info%%:*}
    line=${caller_info##*:}
  else
    file="unknown"
    line=0
  fi

  # Resolve and shorten file path once
  if resolved=$(realpath "${file}" 2>/dev/null); then
    if [[ -n "${SLF4_ROOT}" && "${resolved}" == "${SLF4_ROOT}"* ]]; then
      file=${resolved#"${SLF4_ROOT}"/}
    else
      file=${resolved}
    fi
  fi

  location="${file}:${line}"
  if [[ ${#location} -gt 15 ]]; then
    location="${location:$((${#location}-15))}"
  fi

  prefix="${date} ${time} ${pid} ${level} ${location} - "

  if [[ $# -eq 0 ]]; then
    # When piped, always emit explanatory first line, then stream piped content
    if [[ "${LOG_CONSOLE}" == 1 ]]; then
      printf '%b\n' "${prefix}(message from pipe follows below)"
      while IFS= read -r line; do
        printf '%s\n' "${line}"
      done
    else
      printf '%b\n' "${prefix}(message from pipe follows below)" >>"${SL_LOGFILE}"
      while IFS= read -r line; do
        printf '%s\n' "${line}" >>"${SL_LOGFILE}"
      done
    fi
  else
    # Single-line message from args
    if [[ "${LOG_CONSOLE}" == 1 ]]; then
      printf '%b\n' "${prefix}$*"
    else
      printf '%b\n' "${prefix}$*" >>"${SL_LOGFILE}"
    fi
  fi
}

# Helper: return caller as file:line for the first non-logger frame
__slf4_get_caller() {
  local slf4_file idx c c_line c_file c_real src_index src real_src last_index
  slf4_file="${SLF4_FILE:-}"
  if [[ -z "${slf4_file}" ]]; then
    slf4_file=$(realpath "${BASH_SOURCE[0]}" 2>/dev/null || echo "${BASH_SOURCE[0]}")
  fi

  idx=1
  while c=$(caller ${idx} 2>/dev/null); do
    c_line=${c%% *}
    c_file=${c##* }
    if [[ -n "${c_file}" ]]; then
      c_real=$(realpath "${c_file}" 2>/dev/null || echo "${c_file}")
      if [[ "${c_real}" != "${slf4_file}" ]]; then
        printf '%s:%s' "${c_file}" "${c_line}"
        return 0
      fi
    fi
    idx=$((idx + 1))
  done

  for src_index in "${!BASH_SOURCE[@]}"; do
    src=${BASH_SOURCE[src_index]}
    real_src=$(realpath "${src}" 2>/dev/null || echo "${src}")
    if [[ "${real_src}" != "${slf4_file}" ]]; then
      if [[ ${src_index} -gt 0 ]]; then
        printf '%s:%s' "${src}" "${BASH_LINENO[$((src_index-1))]:-0}"
      else
        printf '%s:%s' "${src}" "0"
      fi
      return 0
    fi
  done

  last_index=$((${#BASH_SOURCE[@]} - 1))
  printf '%s:%s' "${BASH_SOURCE[last_index]}" "${BASH_LINENO[$((last_index-1))]:-0}"
}

sl_init() {
  local start_date start_time start curDir res
  start_date="$(date +%F)"
  start_time="$(date +%H%M%S)"
  start="${start_date}_${start_time}"

  declare -g SLF4_ROOT
  # Resolve to the absolute real path
  SLF4_ROOT="${SL_SCRIPT}"
  while [[ -L "${SLF4_ROOT}" ]]; do
    curDir=$(cd -P "$(dirname "${SLF4_ROOT}")" >/dev/null 2>&1 && pwd)
    SLF4_ROOT=$(readlink "${SLF4_ROOT}")
    [[ ${SLF4_ROOT} != /* ]] && SLF4_ROOT=${curDir}/${SLF4_ROOT}
  done
  SLF4_ROOT=$(cd -P "$(dirname "${SLF4_ROOT}")" >/dev/null 2>&1 && pwd)

  # Cache absolute path to the logger file (used by caller lookup)
  declare -g SLF4_FILE
  SLF4_FILE=$(realpath "${BASH_SOURCE[0]}" 2>/dev/null || echo "${BASH_SOURCE[0]}")

  # If git is supported, try to find parent repository root
  if command -v git &>/dev/null; then
    curDir="$(cd "${SLF4_ROOT}" && git rev-parse --show-toplevel)"
    res=$?
    # Walk-up the tree to exit any potential git repository
    while [[ ${res} -eq 0 ]]; do
      # Check if parent is inside a git repository
      if cd "${curDir}/.." && git rev-parse --is-inside-work-tree &>/dev/null; then
        curDir="$(cd "${curDir}/.." && git rev-parse --show-toplevel)"
        curDir="$(realpath "${curDir}")"
      else
        SLF4_ROOT="${curDir}"
        break # We've escaped outside of the git repo
      fi
    done
    # Make sure CWD was not moidified
    cd "${SL_CWD}" || return 1
  fi

  # Path Configuration
  declare -g SL_LOGFILE
  SL_LOGFILE="$(basename "${SL_SCRIPT}")"
  SL_LOGFILE="${SLF4_ROOT}/.log/${SL_LOGFILE%.*}_${start}.log"

  # Setup logging
  mkdir -p "$(dirname "${SL_LOGFILE}")" # Create log directory
  exec 3>&1 4>&2                        # Backup old descriptors
  trap 'exec 2>&4 1>&3' 0 1 2 3         # Restore in case of signals
  # shellcheck disable=2312
  exec &> >(tee -a "${SL_LOGFILE}") # Redirect output
}

###########################
###### Startup logic ######
###########################
SL_SCRIPT="${0}"
SL_CWD=$(pwd)

# Get root directory of the project
# https://stackoverflow.com/a/246128
SL_SOURCE=${BASH_SOURCE[0]}
while [[ -L "${SL_SOURCE}" ]]; do # resolve $SL_SOURCE until the file is no longer a symlink
  SL_ROOT=$(cd -P "$(dirname "${SL_SOURCE}")" >/dev/null 2>&1 && pwd)
  SL_SOURCE=$(readlink "${SL_SOURCE}")
  [[ ${SL_SOURCE} != /* ]] && SL_SOURCE=${SL_ROOT}/${SL_SOURCE} # if $SL_SOURCE was a relative symlink, we need to resolve it relative to the path where the symlink file was located
done
SL_ROOT=$(cd -P "$(dirname "${SL_SOURCE}")" >/dev/null 2>&1 && pwd)
SL_ROOT=$(realpath "${SL_ROOT}/..")

if [[ -p /dev/stdin ]] && [[ -z ${BASH_SOURCE[0]} ]]; then
  # This script was piped
  echo "ERROR: This script cannot be piped"
  exit 1
elif [[ ${BASH_SOURCE[0]} != "${0}" ]]; then
  # This script was sourced
  sl_init
else
  # This script was executed
  echo "ERROR: This script cannot be executed"
  exit 1
fi
