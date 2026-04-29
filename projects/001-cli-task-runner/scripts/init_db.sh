#!/usr/bin/env bash
set -eou pipefail

# =========================================================================
# Config / Constants
# =========================================================================
SCRIPT_DIR=$(cd -- "$(dirname "${BASH_SOURCE[0]}")" && pwd)
ROOT_DIR=$(cd "${SCRIPT_DIR}/.." && pwd)
LIBS_DIR="${ROOT_DIR}/libs"

# source required libs
required_libs=("lib_utils.sh")

[[ -d "$LIBS_DIR" ]] || {
    printf '%s\n' "ERROR: Libs directory $LIBS_DIR not found" >&2
    exit 1
}

for lib in "${required_libs[@]}"; do
    lib_path="${LIBS_DIR}/${lib}"

    [[ -r "$lib_path" ]] || {
        printf '%s\n' "ERROR: Required lib $lib does not exist or is not readable" >&2
        exit 1
    }

    source "$lib_path" || {
        printf '%s\n' "ERROR: Could not load lib $lib_path"
        exit 1
    }
done


# data directory must be provided
DATA_DIR="${1:-}"
[[ -z "$DATA_DIR" ]] && { log_error "No data directory provided"; exit 1; }
[[ -d "$DATA_DIR" ]] || { log_error "Invalid data directory: $DATA_DIR"; exit 1; }

# Database directories
DB_DIR="${DATA_DIR}/tasks_db"
TABLES_DIR="${DB_DIR}/tables"
SEQS_DIR="${DB_DIR}/seq"
LOCKS_DIR="${DB_DIR}/locks"
TMP_DIR="${DB_DIR}/tmp"

# Schema Directory
SCHEMA_DIR="${ROOT_DIR}/schema"

# Row Field Separator
FS='|'

# =========================================================================
# Utils
# =========================================================================

# TODO: Handle tidy up on failure/partial failure
# TODO: Current Logging approach is masking underlying failure codes on errors, should capture these
_db_is_initialised() {
    
    log_info "Checking if database is initialised..."
    
    local db_dirs
    local db_version="${DB_DIR}/VERSION"

    # check root db directory exists
    [[ -d "$DB_DIR" ]] || return 1
    log_info "Database Root $DB_DIR exists"

    # check db sub directories exist
    db_dirs=("$TABLES_DIR" "$LOCKS_DIR" "$SEQS_DIR" "$TMP_DIR")
    for dir in "${db_dirs[@]}"; do
        [[ -d "$dir" ]] || return 1
    done
    log_info "Database subdirectories exist"

    # check version file exists
    [[ -r "$db_version" ]] || return 1
    log_info "Database version valid; Database is initialised"
}


_db_init_db() {
    if _db_is_initialised; then
        log_info "Database is already initialised"
        return 0
    fi

    log_info "Initialising database..."

    local db_dirs
    db_dirs=("$TABLES_DIR" "$LOCKS_DIR" "$SEQS_DIR" "$TMP_DIR")
    
    # create database root directory
    log_info "Initialising database root $DB_DIR"
    mkdir -p "${DB_DIR}" || { log_error "Failed to create database root $DB_DIR"; return 1}

    # create database directories
    log_info "Initialising data directories"
    for dir in "${db_dirs[@]}"; do
        mkdir -p "$dir" || { log_error "Failed to create DB directory: $dir"; return 1; }
    done

    # setup global lock
    log_info "Initialising database locks"
    touch "$LOCKS_DIR/db_global.lock" || {
        log_error "Failed to initialise global lock"
        return 1
    }

    # create a VERSION file to flag 
    touch "${DB_DIR}/VERSION"
    printf '%s' 'TASKS_DB V1.0' > "${DB_DIR}/VERSION"

    # bind global variable
    GLOBAL_DB_LOCK="$LOCKS_DIR/db_global.lock"
    return 0
}


_db_init_schema() {
    [[ -d "$SCHEMA_DIR" ]] || { log_error "Schema directory not found: $SCHEMA_DIR"; return 1; }
    [[ -f "$GLOBAL_DB_LOCK" ]] || { log_error "Global write lock not found: $GLOBAL_DB_LOCK"; return 1; }

    local table_schemata
    mapfile -t table_schemata< <(cd "$SCHEMA_DIR" && ls *.schema)

    [[ "${#table_schemata[@]}" -eq 0 ]] && { log_warn "No table schemas found; schema dir: $SCHEMA_DIR"; return 1; }
    
    log_info "Building schema..."
    for schema_file in "${table_schemata[@]}"; do
        
        # basic validation step
        [[ -z "$schema_file" || ! "$schema_file" =~ ^([a-zA-Z]+.schema)$ ]] && {
            log_warn "Invalid schema file: $schema_file; skipping..."
            continue
        }

        log_info "Building $schema_file..."
        # Attempt to build table
        # TODO: handle failure
        _db_create_table "$schema_file"
    done

}

_db_create_table() {
    local table_schema="${1:-}"
    
    # parse schema
    log_info "Parsing schema $table_schema"
    local table_name="${table_schema%%.*}"
    local cols=()
    local seqs=()

    # extract column names and types
    while  read -r col type; do
        [[ -n "$col" ]] && cols+=("$col")
        [[ -n "$type" && "$type" == 'AUTO' ]] && seqs+=("$col")
        
    done < "${SCHEMA_DIR}/${table_schema}"

    # format table header row (human readable tables)
    table_header="$(_db_format_row cols)"

    # critical section: acquire global db write lock
    flock -x  "$GLOBAL_LOCK"
    
    [[ -d "$TABLES_DIR" ]] || mkdir -p 



    if [[ -d "$table_dir" ]]; then
        log_info "Table $table_name already exists"
        return 0
    fi

    # make table directory
    mkdir -p "$table_dir" || {
        log_error "Failed to create table directory: $table_dir"
        return 1
    }

    # make table file

    # make seq files

    # make lock files


    # end critical section: release global db write lock
    flock -u "$GLOBAL_DB_LOCK"
    
  
    # extract table name
    # create table file
    # format header row based on cols
    # write header row to files
    # create sequence files
    # create write lock file in locks/dir

}

_db_format_row() {
    declare -n vals_arr
    # TODO: handle case when no vals passed in
    vals_arr=${1}
    
    [[ -R $vals_arr ]] && {
        log_error "_db_format_row: No values provided"
        return 1
    }

    local num_vals="${#vals_arr[@]}"
    local formatted_row="${vals_arr[0]}"
    
    for ((i=1; i<$num_vals; i++)); do
        formatted_row+="${FS}${vals_arr[$i]}"
    done
    printf '%s\n' $formatted_row
    return 0
}


# =========================================================================
# Main
# =========================================================================

_db_init_db
_db_init_schema