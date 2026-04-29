#!/usr/bin/env bash

# ====================================================================================================
# Logging Helpers
# ====================================================================================================

logger() {
    local level="${1:-}"
    shift || true

    [[ "$level" =~ ^(INFO|WARN|ERROR|DEBUG)$ ]] || {
        printf '%s\n' "ERROR: Invalid/missing log level (INFO|WARN|ERROR|DEBUG)" >&2
        return 1
    }

    [[ $# -gt 0 ]] || {
        printf '%s\n' "ERROR: No log message provided" >&2
        return 1
    }

    local msg="$*"
    local line
    line=$(printf '[%s] [%s] %s' "$(date '+%Y-%m-%d %H:%M:%S')" "$level" "$msg")

    # ERROR/WARN to stderr, INFO/DEBUG to stdout
    if [[ "$level" == "ERROR" || "$level" == "WARN" ]]; then
        printf '%s\n' "$line" >&2
    else
        printf '%s\n' "$line"
    fi    
    return 0
}

log_info () {
    msg="$*"
    logger 'INFO' "$msg"
}

log_warn() {
    msg="$*"
    logger 'WARN' "$msg"
}

log_error() {
    msg="$*"
    logger 'ERROR' "$msg"
}

log_debug() {
    msg="$*"
    logger 'DEBUG' "$msg"
}
