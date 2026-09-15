#!/usr/bin/env bash

# ============================================================================
# findlog.sh
#
# Secure, read-only systemd journal troubleshooting tool.
#
# Features:
#   - Literal text search by default
#   - Extended regular-expression search
#   - Case-sensitive / insensitive search
#   - Time filtering
#   - Service/unit filtering
#   - Boot filtering
#   - Priority filtering
#   - PID / UID filtering
#   - Identifier filtering
#   - Facility filtering
#   - Kernel-only logs
#   - System/user journal
#   - Follow/live mode
#   - List boots
#   - Journal disk usage
#   - Journal verification
#   - Result limiting
#   - Before/after context
#   - UTC output
#   - JSON output
#   - Quiet mode
#
# SECURITY:
#   This script is intentionally READ-ONLY.
#
#   It does NOT:
#       - execute commands from log contents
#       - use eval
#       - modify system configuration
#       - delete journal logs
#       - vacuum journal logs
#       - change permissions
#       - make network connections
#       - collect credentials
#
# Requirements:
#   - Bash 4+
#   - systemd / journalctl
#   - grep
#
# Author: Hanzo
# Created: 2022-09-09
# Modified: 2026-09-15
# ============================================================================

set -u
set -o pipefail

readonly SCRIPT_NAME="$(basename "$0")"
readonly DEFAULT_LINES=20
readonly DEFAULT_CONTEXT=0

# ============================================================================
# Colors
# ============================================================================

if [[ -t 1 ]]; then
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[1;33m'
    BLUE='\033[0;34m'
    CYAN='\033[0;36m'
    BOLD='\033[1m'
    NC='\033[0m'
else
    RED=''
    GREEN=''
    YELLOW=''
    BLUE=''
    CYAN=''
    BOLD=''
    NC=''
fi

# ============================================================================
# Functions
# ============================================================================

error() {
    printf '%bError:%b %s\n' "$RED" "$NC" "$*" >&2
}

info() {
    printf '%b%s%b\n' "$BLUE" "$*" "$NC"
}

success() {
    printf '%b%s%b\n' "$GREEN" "$*" "$NC"
}

warning() {
    printf '%b%s%b\n' "$YELLOW" "$*" "$NC"
}

die() {
    error "$*"
    exit 2
}

header() {
    printf '\n%b==============================================%b\n' "$CYAN" "$NC"
    printf '%b%s%b\n' "$BOLD" "$1" "$NC"
    printf '%b==============================================%b\n' "$CYAN" "$NC"
}

usage() {
    cat <<EOF

$SCRIPT_NAME - Secure systemd journal troubleshooting tool

USAGE
    $SCRIPT_NAME [OPTIONS] [SEARCH_TEXT]

SEARCH
    -c, --case-sensitive
        Case-sensitive search.

    -E, --regex
        Treat SEARCH_TEXT as an extended regular expression.

        Default is literal/fixed-string search.

    -n, --lines NUMBER
        Maximum number of matching entries.

        Default: $DEFAULT_LINES

    -C, --context NUMBER
        Show NUMBER journal entries before and after each match.

        Example:
            --context 3

TIME
    -s, --since TIME
        Search logs since TIME.

        Examples:
            "10 minutes ago"
            "1 hour ago"
            today
            yesterday
            "2026-09-15 00:00:00"

    -U, --until TIME
        Search logs until TIME.

SERVICE / PROCESS
    -u, --unit UNIT
        Search a systemd service/unit.

        Examples:
            sshd
            nginx
            docker.service

    --pid PID
        Search messages from a specific PID.

    --uid UID
        Search messages associated with a UID.

    -i, --identifier NAME
        Filter by SYSLOG_IDENTIFIER.

    -F, --facility FACILITY
        Filter by syslog facility.

BOOT
    -b, --boot BOOT
        Search a specific boot.

        Examples:
            current
            previous
            -1
            -2
            BOOT_ID

    --list-boots
        List available boots and exit.

PRIORITY
    -p, --priority LEVEL
        Filter by journal priority.

        Examples:
            emerg
            alert
            crit
            err
            warning
            notice
            info
            debug

        Ranges:
            err..warning

JOURNAL INFORMATION
    --disk-usage
        Display journal disk usage and exit.

    --verify
        Verify journal files and exit.

JOURNAL SOURCE
    -k, --kernel
        Show kernel messages.

    --system
        Use system journal.

    --user
        Use user journal.

OUTPUT
    --utc
        Display timestamps in UTC.

    --full
        Do not truncate fields.

    --all
        Show all fields, including fields with unprintable characters.

    --json
        Output entries as JSON.

    --json-pretty
        Output entries as pretty JSON.

    --cat
        Display only the MESSAGE field.

    -q, --quiet
        Suppress informational output.

LIVE MODE
    -f, --follow
        Follow the journal and search new entries continuously.

HELP
    -h, --help
        Show this help.

EXAMPLES

    Interactive search:
        $SCRIPT_NAME

    Search for a message:
        $SCRIPT_NAME "connection refused"

    Search recent errors:
        $SCRIPT_NAME --since "1 hour ago" --priority err

    Search SSH errors:
        $SCRIPT_NAME --unit sshd --priority err "failed"

    Search today's nginx errors:
        $SCRIPT_NAME --since today --unit nginx --priority err

    Search the previous boot:
        $SCRIPT_NAME --boot previous "error"

    Search kernel errors:
        $SCRIPT_NAME --kernel --priority err

    Search a specific PID:
        $SCRIPT_NAME --pid 1234 "error"

    Show 50 matching entries:
        $SCRIPT_NAME --lines 50 "timeout"

    Show 3 entries before/after each match:
        $SCRIPT_NAME --context 3 "connection refused"

    Follow SSH failures:
        $SCRIPT_NAME --unit sshd --follow "failed"

    Regular expression:
        $SCRIPT_NAME --regex "failed.*connection"

    Case-sensitive search:
        $SCRIPT_NAME --case-sensitive "Connection refused"

    List boots:
        $SCRIPT_NAME --list-boots

    Journal disk usage:
        $SCRIPT_NAME --disk-usage

    Verify journal:
        $SCRIPT_NAME --verify

    JSON:
        $SCRIPT_NAME --json "error"

EXIT STATUS

    0       Match found / operation successful
    1       No matching entry found
    2       Invalid argument or input
    3       journalctl failed
    4       Search operation failed
    127     Required command not found

EOF
}

require_command() {
    local command="$1"

    if ! command -v "$command" >/dev/null 2>&1; then
        error "Required command '$command' was not found."
        exit 127
    fi
}

# ============================================================================
# Dependencies
# ============================================================================

require_command journalctl
require_command grep

# ============================================================================
# Defaults
# ============================================================================

since=""
until_time=""
unit=""
priority=""
boot=""
pid=""
uid=""
identifier=""
facility=""

lines="$DEFAULT_LINES"
context="$DEFAULT_CONTEXT"

follow=false
case_sensitive=false
regex=false
quiet=false

kernel=false
system=false
user=false

utc=false
full=false
all_fields=false

json=false
json_pretty=false
cat_mode=false

list_boots=false
disk_usage=false
verify=false

target_entry=""

# ============================================================================
# Argument parsing
# ============================================================================

while [[ $# -gt 0 ]]; do

    case "$1" in

        -h|--help)
            usage
            exit 0
            ;;

        -q|--quiet)
            quiet=true
            shift
            ;;

        -c|--case-sensitive)
            case_sensitive=true
            shift
            ;;

        -E|--regex)
            regex=true
            shift
            ;;

        -f|--follow)
            follow=true
            shift
            ;;

        -k|--kernel)
            kernel=true
            shift
            ;;

        --system)
            system=true
            shift
            ;;

        --user)
            user=true
            shift
            ;;

        --utc)
            utc=true
            shift
            ;;

        --full)
            full=true
            shift
            ;;

        --all)
            all_fields=true
            shift
            ;;

        --json)
            json=true
            shift
            ;;

        --json-pretty)
            json_pretty=true
            shift
            ;;

        --cat)
            cat_mode=true
            shift
            ;;

        --list-boots)
            list_boots=true
            shift
            ;;

        --disk-usage)
            disk_usage=true
            shift
            ;;

        --verify)
            verify=true
            shift
            ;;

        -s|--since)
            [[ $# -ge 2 ]] || die "$1 requires a value."
            since="$2"
            shift 2
            ;;

        -U|--until)
            [[ $# -ge 2 ]] || die "$1 requires a value."
            until_time="$2"
            shift 2
            ;;

        -u|--unit)
            [[ $# -ge 2 ]] || die "$1 requires a service/unit name."
            unit="$2"
            shift 2
            ;;

        -p|--priority)
            [[ $# -ge 2 ]] || die "$1 requires a priority."
            priority="$2"
            shift 2
            ;;

        -b|--boot)
            [[ $# -ge 2 ]] || die "$1 requires a boot value."
            boot="$2"
            shift 2
            ;;

        --pid)
            [[ $# -ge 2 ]] || die "$1 requires a PID."
            [[ "$2" =~ ^[0-9]+$ ]] ||
                die "PID must be numeric."
            pid="$2"
            shift 2
            ;;

        --uid)
            [[ $# -ge 2 ]] || die "$1 requires a UID."
            [[ "$2" =~ ^[0-9]+$ ]] ||
                die "UID must be numeric."
            uid="$2"
            shift 2
            ;;

        -i|--identifier)
            [[ $# -ge 2 ]] || die "$1 requires an identifier."
            identifier="$2"
            shift 2
            ;;

        -F|--facility)
            [[ $# -ge 2 ]] || die "$1 requires a facility."
            facility="$2"
            shift 2
            ;;

        -n|--lines)
            [[ $# -ge 2 ]] || die "$1 requires a number."
            [[ "$2" =~ ^[1-9][0-9]*$ ]] ||
                die "--lines must be a positive integer."
            lines="$2"
            shift 2
            ;;

        -C|--context)
            [[ $# -ge 2 ]] || die "$1 requires a number."
            [[ "$2" =~ ^[0-9]+$ ]] ||
                die "--context must be zero or a positive integer."
            context="$2"
            shift 2
            ;;

        --)
            shift
            break
            ;;

        -*)
            die "Unknown option: $1"

            ;;

        *)
            if [[ -z "$target_entry" ]]; then
                target_entry="$1"
            else
                target_entry+=" $1"
            fi
            shift
            ;;

    esac

done

# ============================================================================
# Validate incompatible options
# ============================================================================

if [[ "$system" == true && "$user" == true ]]; then
    die "--system and --user cannot be used together."
fi

if [[ "$json" == true && "$json_pretty" == true ]]; then
    die "--json and --json-pretty cannot be used together."
fi

if [[ "$cat_mode" == true &&
      ( "$json" == true || "$json_pretty" == true ) ]]; then
    die "--cat cannot be combined with JSON output."
fi

# ============================================================================
# Journal information operations
# ============================================================================

if [[ "$list_boots" == true ]]; then

    [[ "$quiet" == true ]] || header "AVAILABLE BOOTS"

    if ! journalctl --list-boots --no-pager; then
        error "Unable to list journal boots."
        exit 3
    fi

    exit 0
fi

if [[ "$disk_usage" == true ]]; then

    [[ "$quiet" == true ]] || header "JOURNAL DISK USAGE"

    if ! journalctl --disk-usage --no-pager; then
        error "Unable to determine journal disk usage."
        exit 3
    fi

    exit 0
fi

if [[ "$verify" == true ]]; then

    [[ "$quiet" == true ]] || header "JOURNAL VERIFICATION"

    if ! journalctl --verify --no-pager; then
        error "Journal verification reported an error."
        exit 3
    fi

    [[ "$quiet" == true ]] || success "Journal verification completed."

    exit 0
fi

# ============================================================================
# Get search text
# ============================================================================

if [[ -z "$target_entry" ]]; then

    if [[ "$quiet" == false ]]; then
        printf '\n'
        printf 'Hello %s!\n\n' "${USER:-User}"
    fi

    read -r -p \
        "Enter/paste the log entry to search for: " \
        target_entry
fi

if [[ -z "$target_entry" ]]; then
    error "Search text cannot be empty."
    exit 2
fi

# ============================================================================
# Build journalctl arguments
# ============================================================================

journal_args=(
    --no-pager
    --reverse
)

if [[ "$full" == true ]]; then
    journal_args+=(--full)
fi

if [[ "$all_fields" == true ]]; then
    journal_args+=(--all)
fi

if [[ "$utc" == true ]]; then
    journal_args+=(--utc)
fi

if [[ "$kernel" == true ]]; then
    journal_args+=(--dmesg)
fi

if [[ "$system" == true ]]; then
    journal_args+=(--system)
fi

if [[ "$user" == true ]]; then
    journal_args+=(--user)
fi

if [[ -n "$since" ]]; then
    journal_args+=(--since "$since")
fi

if [[ -n "$until_time" ]]; then
    journal_args+=(--until "$until_time")
fi

if [[ -n "$unit" ]]; then
    journal_args+=(--unit "$unit")
fi

if [[ -n "$priority" ]]; then
    journal_args+=(--priority "$priority")
fi

if [[ -n "$boot" ]]; then
    case "$boot" in
        current)
            journal_args+=(--boot 0)
            ;;
        previous)
            journal_args+=(--boot -1)
            ;;
        *)
            journal_args+=(--boot "$boot")
            ;;
    esac
fi

if [[ -n "$pid" ]]; then
    journal_args+=(--pid "$pid")
fi

if [[ -n "$uid" ]]; then
    journal_args+=(--uid "$uid")
fi

if [[ -n "$identifier" ]]; then
    journal_args+=(--identifier "$identifier")
fi

if [[ -n "$facility" ]]; then
    journal_args+=(--facility "$facility")
fi

if [[ "$follow" == true ]]; then
    journal_args+=(--follow)
fi

# ============================================================================
# Output format
# ============================================================================

if [[ "$json" == true ]]; then
    journal_args+=(--output=json)

elif [[ "$json_pretty" == true ]]; then
    journal_args+=(--output=json-pretty)

elif [[ "$cat_mode" == true ]]; then
    journal_args+=(--output=cat)
fi

# ============================================================================
# Build grep arguments
# ============================================================================

grep_args=()

if [[ "$case_sensitive" == false ]]; then
    grep_args+=(-i)
fi

if [[ "$regex" == true ]]; then
    grep_args+=(-E)
else
    # Safe default: search literal text.
    grep_args+=(-F)
fi

# ============================================================================
# Display configuration
# ============================================================================

if [[ "$quiet" == false ]]; then

    header "JOURNAL LOG SEARCH"

    printf 'Search      : %s\n' "$target_entry"

    [[ -n "$since" ]] &&
        printf 'Since       : %s\n' "$since"

    [[ -n "$until_time" ]] &&
        printf 'Until       : %s\n' "$until_time"

    [[ -n "$unit" ]] &&
        printf 'Unit        : %s\n' "$unit"

    [[ -n "$priority" ]] &&
        printf 'Priority    : %s\n' "$priority"

    [[ -n "$boot" ]] &&
        printf 'Boot        : %s\n' "$boot"

    [[ -n "$pid" ]] &&
        printf 'PID         : %s\n' "$pid"

    [[ -n "$uid" ]] &&
        printf 'UID         : %s\n' "$uid"

    [[ -n "$identifier" ]] &&
        printf 'Identifier  : %s\n' "$identifier"

    [[ -n "$facility" ]] &&
        printf 'Facility    : %s\n' "$facility"

    printf 'Max matches : %s\n' "$lines"
    printf 'Context     : %s before / %s after\n' "$context" "$context"

    if [[ "$regex" == true ]]; then
        printf 'Search mode : Extended regular expression\n'
    else
        printf 'Search mode : Literal string\n'
    fi

    if [[ "$case_sensitive" == true ]]; then
        printf 'Case        : Sensitive\n'
    else
        printf 'Case        : Insensitive\n'
    fi

    [[ "$follow" == true ]] &&
        printf 'Mode        : Live / follow\n'

    info "----------------------------------------------"
    printf '\n'

fi

# ============================================================================
# Search
# ============================================================================

if [[ "$follow" == true ]]; then

    # Live mode intentionally continues until Ctrl+C.
    #
    # We do not use -m here because the purpose of --follow is
    # continuous monitoring.

    grep_args+=(--)

    if ! journalctl "${journal_args[@]}" |
        grep "${grep_args[@]}" "$target_entry"; then

        statuses=("${PIPESTATUS[@]}")

        journal_status="${statuses[0]}"
        grep_status="${statuses[1]}"

        # grep returns 1 when nothing has matched yet.
        # In follow mode that is not an error.
        if [[ "$journal_status" -ne 0 &&
              "$journal_status" -ne 141 ]]; then
            error "journalctl failed with exit code $journal_status."
            exit 3
        fi

        if [[ "$grep_status" -gt 1 ]]; then
            error "Search operation failed with exit code $grep_status."
            exit 4
        fi
    fi

    exit 0
fi

# ============================================================================
# Normal search
# ============================================================================

# -m LIMIT stops grep after LIMIT matching entries.
#
# -C CONTEXT displays entries before and after each match.
#
# We intentionally accept journalctl status 141 (SIGPIPE). This can happen
# because grep stops reading after finding the requested number of matches.
#
# The -- separator is important: it prevents the search text itself from
# being interpreted as a grep option.

grep_args+=(
    -m "$lines"
    -C "$context"
    --
)

journalctl "${journal_args[@]}" |
    grep "${grep_args[@]}" "$target_entry"

statuses=("${PIPESTATUS[@]}")

journal_status="${statuses[0]}"
grep_status="${statuses[1]}"

# ============================================================================
# Handle journalctl errors
# ============================================================================

if [[ "$journal_status" -ne 0 &&
      "$journal_status" -ne 141 ]]; then

    error "journalctl failed with exit code $journal_status."
    error "You may need permission to read the system journal."
    exit 3
fi

# ============================================================================
# Handle grep/search result
# ============================================================================

case "$grep_status" in

    0)
        if [[ "$quiet" == false ]]; then
            printf '\n'
            success "Matching journal entry found."
        fi

        exit 0
        ;;

    1)
        if [[ "$quiet" == false ]]; then
            printf '\n'
            warning "No matching journal entry found."
        fi

        exit 1
        ;;

    *)
        error "Search operation failed with exit code $grep_status."
        exit 4
        ;;

esac
