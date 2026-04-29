# -----------------------------------------------------------------------------
# DB MODULE (private state prefixed with _db_)
# -----------------------------------------------------------------------------
# WARN: 
#   - All functions that mutate files must be called under the global lock \
#     unless explicitly documented otherwise.
#   
#   - Any function suffixed with _nolock is not thread safe under concurrency;
#     Such functions expect the caller to acquire locks; Failure to do so
#     may lead to data corruption and/or race conditions.
#     Additional safety guards are included to prevent accidental misuse. 


# ------------------ private module state -------------------------------------
# set by init_db
_db_root=""
_db_tables_dir=""
_db_seq_dir=""
_db_locks_dir=""
_db_tmp_dir=""
_db_meta_dir=""
_db_committed_schema_dir=""
_db_field_separator=""
_db_init_marker=""
_db_schema_init_marker=""
_db_lock_held=0

# ------------------ private module error state -------------------------------
_db_err_msg=""
_db_err_ctx=""

# ------------------ private utils --------------------------------------------

_db_set_error() {
    # Usage: _db_set_error <message> [context]
    local msg="$1"
    local caller_fn="${FUNCNAME[1]}"
    _db_err_msg="$msg"
    _db_err_ctx="$caller_fn"
}

_db_add_error_ctx() {
    local caller_fn="${FUNCNAME[1]}"
    _db_err_ctx="${_db_err_ctx:+${_db_err_ctx} | }${caller_fn}"
}

_db_clear_error() {
    _db_err_msg=""
    _db_err_ctx=""
}

_db_bootstrap_db_config() {
    # Purpose:
    #   Derive and set all internal DB module paths fomr environment/config.
    #   Does NOT perform any filesystem mutations.
    #
    # Requirements:
    #   - db_dir arg must be passed and must be a valid directory
    #  
    # Returns:
    #   0 on success
    #   1 on configuration error
    
    # --- Validate DB_DIR ---
    local db_dir="${1:-}"

    [[ -n "${db_dir}" ]] || { _db_set_error "Bad usage; no DB_DIR provided"; return 1; }
        
    # --- Set core paths ---
    _db_root="${db_dir}"
    _db_tables_dir="${_db_root}/tables"
    _db_seq_dir="${_db_root}/seq"
    _db_locks_dir="${_db_root}/locks"
    _db_tmp_dir="${_db_root}/tmp"
    _db_meta_dir="${_db_root}/meta"
    _db_committed_schema_dir="${_db_meta_dir}/schema"

    # --- Marker files ---
    _db_init_marker="${_db_root}/.db_initialized"
    _db_schema_init_marker="${_db_root}/.schema_initialized"

    # --- Misc config ---
    _db_field_separator='|'

    return 0
}

_db_is_config_set() {    
    # Validate required config is set (config set via _db_bootstrap_config)
    local missing_vars=()
    local missing=""

    [[ -n "${_db_root:-}" ]] || missing_vars+=('_db_root')
    [[ -n "${_db_tables_dir:-}" ]] || missing_vars+=('_db_tables_dir')
    [[ -n "${_db_seq_dir:-}" ]] || missing_vars+=('_db_seq_dir')
    [[ -n "${_db_locks_dir:-}" ]] || missing_vars+=('_db_locks_dir')
    [[ -n "${_db_tmp_dir:-}" ]] || missing_vars+=('_db_tmp_dir')
    [[ -n "${_db_meta_dir:-}" ]] || missing_vars+=('_db_meta_dir')
    [[ -n "${_db_committed_schema_dir:-}" ]] || missing_vars+=('_db_committed_schema_dir')
    [[ -n "${_db_init_marker:-}" ]] || missing_vars+=('_db_init_marker')
    [[ -n "${_db_schema_init_marker:-}" ]] || missing_vars+=('_db_schema_init_marker')
    [[ -n "${_db_field_separator:-}" ]] || missing_vars+=('_db_field_separator')

    if (( ${#missing_vars[@]} > 0 )); then
        # Join nicely: a, b, c
        missing="$(IFS=', '; printf '%s' "${missing_vars[*]}")"
        _db_set_error "Configuration not set; missing: ${missing}"
        return 1
    fi

    return 0
}

_db_is_lock_held() {
    case "${_db_lock_held:-0}" in
        1) return 0 ;; # true: held
        0) return 1 ;; # false: not held
        *) _db_set_error "Corrupt lock state: _db_lock_held='${_db_lock_held}'"; return 1 ;;
    esac
}


_db_is_init() {
    # check for db initialized marker file
    [[ -n "${_db_init_marker}" && -f "${_db_init_marker}" ]] || return 1
}

_db_schema_is_init() {
    # check for db schema initialized marker file
    [[ -n "${_db_schema_init_marker}" && -f "${_db_schema_init_marker}" ]] || return 1
}

# row formatter helper function
_db_format_row() {
    local arr_name="${1:-}"
    local nums_vals=0
    local formatted_row=""
    
    [[ -n "$arr_name" ]] || { _db_set_error "No array name provided"; return 1; }
        
    declare -n vals_arr="$arr_name" || {
        _db_set_error "Invalid nameref: $arr_name"
        return 1
    }

    num_vals="${#vals_arr[@]}"
    [[ "$num_vals" -eq 0 ]] && { _db_set_error "Values array is empty"; return 1; }
        
    [[ -n "${_db_field_separator}" ]] || { _db_set_error "_db_field_separator not set"; return 1; }
        
    formatted_row="${vals_arr[0]}"
    for ((i=1; i<$num_vals; i++)); do
        formatted_row+="${_db_field_separator}${vals_arr[$i]}"
    done

    printf '%s\n' "$formatted_row"
    return 0
}


_db_create_file_atomic_nolock() {
    # Usage: _db_create_file_atomic_nolock <full_file_path> [initial contents]
    local f_path="${1:-}"
    shift || true
    local init_data="$*"
    local f_dir=""
    local f_name=""
    local tmp_file=""

    # Defensive safety guards
    # check _db_lock_is_held flag & check private config state is set
    _db_is_lock_held || { _db_add_error_ctx; return 1; }
    _db_is_config_set || { _db_add_error_ctx; return 1; }

    # validate inputs
    [[ -n "$f_path" ]] || { _db_set_error "No file path provided"; return 1; }
        
    f_dir=$(dirname "$f_path") || { _db_set_error "Error extracting directory from $f_path"; return 1; }
        
    [[ -d "$f_dir" ]] || {
        _db_set_error "Directory $f_dir (from path $f_path) does not exist or is not a directory"
        return 1
    }

    f_name=$(basename "$f_path") || { _db_set_error "Error extracting file name from $f_path"; return 1; }
        
    [[ -n "$f_name" ]] || { _db_set_error "Bad file path $f_path; must be a full file path"; return 1; }
        
    # atomic file creation (tmp + mv), rollback on failure
    tmp_file="$(mktemp "${_db_tmp_dir}/${f_name}.XXXXXX" 2>/dev/null)" || {
        _db_set_error "Failed to create temp file: $tmp_file"
        return 1
    }

    if [[ -n "$init_data" ]]; then
        if ! printf '%s\n' "$init_data" >"$tmp_file"; then
            _db_set_error "Failed to initialize $tmp_file"
            rm -f "$tmp_file" >/dev/null 2>&1 || true
            return 1
        fi
    fi

    if ! mv "$tmp_file" "$f_path"; then
        _db_set_error "Failed to commit $tmp_file (mv failed)"
        rm -f "$tmp_file" >/dev/null 2>&1 || true
        return 1
    fi

    return 0
}

_db_schema_drift_detected_nolock() {
    # Usage: _db_schema_drift_detected_nolock <user_schema_file_full_path>
    # Returns:
    #   0 -> no drift (matches OR committed missing)
    #   1 -> drift detected (committed exists and differs)
    #   2 -> error
    local user_schema="${1:-}"
    local base=""
    local committed=""

    # Defensive safety guards
    # check _db_lock_is_held flag & check private config state is set
    _db_is_lock_held || { _db_add_error_ctx; return 1; }
    _db_is_config_set || { _db_add_error_ctx; return 1; }


    [[ -r "$user_schema" ]] || { _db_set_error "Schema not readable: $user_schema"; return 1; }
        
    base="$(basename "$user_schema")" || {
        _db_set_error "Failed to get basename: $user_schema"
        return 1
    }

    committed="${_db_committed_schema_dir}/${base}"

    # If committed schema doesn't exist yet, drift can't be detected
    [[ -f "$committed" ]] || return 0

    cmp -s "$user_schema" "$committed"
    case $? in
        0) return 0 ;;  # identical
        1) return 1 ;;  # drift
        *) _db_set_error "cmp failed while comparing schema files"; return 2 ;;
    esac
}

_db_stage_schema_file_nolock() {
    # Usage: _db_stage_schema_file_nolock <user_schema_file_full_path>
    # Prints staged temp file path to stdout
    local user_schema="${1:-}"
    local base=""
    local staged=""

    # Defensive safety guards
    # check _db_lock_is_held flag & check private config state is set
    _db_is_lock_held || { _db_add_error_ctx; return 1; }
    _db_is_config_set || { _db_add_error_ctx; return 1; }


    [[ -r "$user_schema" ]] || { _db_set_error "Schema not readable: $user_schema"; return 1; }

    base="$(basename "$user_schema")" || {
        _db_set_error "Failed to get basename: $user_schema"
        return 1
    }

    staged="$(mktemp "${_db_tmp_dir}/${base}.stage.XXXXXX" 2>/dev/null)" || {
        _db_set_error "Failed to create staged schema temp file"
        return 1
    }

    if ! cp "$user_schema" "$staged"; then
        rm -f "$staged" >/dev/null 2>&1 || true
        _db_set_error "Failed to stage schema file"
        return 1
    fi

    printf '%s\n' "$staged"
    return 0
}

_db_commit_staged_schema_nolock() {
    # Usage: _db_commit_staged_schema_nolock <staged_schema_temp_path> <user_schema_file_full_path>
    local staged="${1:-}"
    local user_schema="${2:-}"
    local base=""
    local committed=""

    # Defensive safety guards
    # check _db_lock_is_held flag & check private config state is set
    _db_is_lock_held || { _db_add_error_ctx; return 1; }
    _db_is_config_set || { _db_add_error_ctx; return 1; }


    [[ -f "$staged" ]] || { _db_set_error "Staged schema file missing: $staged"; return 1; }
        
    base="$(basename "$user_schema")" || {
        _db_set_error "Failed to get basename: $user_schema"
        return 1
    }

    committed="${_db_committed_schema_dir}/${base}"

    if ! mv "$staged" "$committed"; then
        _db_set_error "Failed to commit schema snapshot (mv failed)"
        rm -f "$staged" >/dev/null 2>&1 || true
        return 1
    fi

    return 0
}


_db_create_table_from_committed_schema_nolock () {
    
    local committed_schema="${1:-}"  # expects a full file path to a schema file    
    local base
    local table_name table_header
    local col_name col_type
    local table_cols=()
    local table_seq_cols=()
    local table_file
    local table_lockfile
    local seq_files=()
    local dirty_files=()
    local init_seq_value=0

    # Defensive safety guards
    # check _db_lock_is_held flag & check private config state is set
    _db_is_lock_held || { _db_add_error_ctx; return 1; }
    _db_is_config_set || { _db_add_error_ctx; return 1; }

    # --- Parse schema file ---

    # extract file name
    base="$(basename "$committed_schema")" || {
        _db_set_error "Error extracting file name from $committed_schema"
        return 1
    }

    # extract and validate table name
    table_name="${base%%.*}"
    if [[ -z "$table_name" ]]; then
        _db_set_error "Error parsing table name; schema file $committed_schema"
        return 1
    fi

    # extract table column names and types
    # type=AUTO indicates column should be an auto-generated sequence
    while read -r col_name col_type; do
        # ignore blank lines and comments
        [[ -z "$col_name" || "$col_name" == \#* ]] && continue

        # parse line
        [[ -n "$col_name" ]] && table_cols+=("$col_name")
        [[ -n "$col_type" && "$col_type" == 'AUTO' ]] && table_seq_cols+=("$col_name")
    
    done < "$committed_schema" || {
        _db_set_error "Error parsing table definition; schema file $committed_schema"
        return 1
    }

    # ensure schema file defines at least 1 table column
    if [[ "${#table_cols[@]}" -eq 0 ]]; then
        _db_set_error "No columns defined; schema $committed_schema"
        return 1
    fi


    # --- Build table artefacts ---
    
    # create a human readable table header row
    table_header="$(_db_format_row table_cols)" || { _db_add_error_ctx; return 1; }
    
    # compute all required file paths for table and sequences (if any)
    table_file="${_db_tables_dir}/${table_name}.tbl"

    for col in "${table_seq_cols[@]}"; do
        seq_files+=("${_db_seq_dir}/${table_name}_${col}.seq")
    done

    table_lockfile="${_db_locks_dir}/${table_name}.lock"
    
    # --- Create table, sequence and lock files (Atomic) ---
    # Table file
    if [[ ! -f "$table_file" ]]; then
        {
            _db_create_file_atomic_nolock "$table_file" "$table_header" &&
            dirty_files+=("$table_file")
        } || {
            _db_add_error_ctx
            # rollback 
            rm -f "$table_file" || true 
            return 1
        }
    fi

    # Sequence file
    for seq_file in "${seq_files[@]}"; do
        if [[ ! -f "${seq_file}" ]]; then
            {
                _db_create_file_atomic_nolock "$seq_file" "$init_seq_value" &&
                dirty_files+=("$seq_file")
            } || {
                _db_add_error_ctx
                # Rollback all dirty files
                for dirty_file in "${dirty_files[@]}"; do
                    rm -f "$dirty_file" || true
                done
                return 1
            }
        fi
    done

    # Lock file
    if [[ ! -f "${table_lockfile}" ]]; then
        _db_create_file_atomic_nolock "${table_lockfile}" || {
            _db_add_error_ctx
            # Rollback all dirty files
            for dirty_file in "${dirty_files[@]}"; do
                rm -f "$dirty_file" || true
            done
            return 1
        }
    fi

    return 0
}


_db_create_table_from_user_schema_nolock() {
    
    local user_schema="${1:-}"
    local base
    local committed_schema
    local staged

    # Defensive safety guards
    # check _db_lock_is_held flag & check private config state is set
    _db_is_lock_held || { _db_add_error_ctx; return 1; }
    _db_is_config_set || { _db_add_error_ctx; return 1; }


    # Ensure committed schema dir exists
    [[ -n "${_db_committed_schema_dir:-}" && -d "${_db_committed_schema_dir}" ]] || {
        _db_set_error "_db_committed_schema_dir is not set or is not a directory"
        return 1
    }

    # --- Validate input file ---
    [[ -n "${user_schema}" ]] || { _db_set_error "Bad arguments; expected user schema file"; return 1; }
        
    [[ -r "${user_schema}" ]] || {
        _db_set_error "Bad arguments; schema file: '$user_schema' is not readable"
        return 1
    }

    base="$(basename "$user_schema")" || { _db_set_error "Failed to get basename: $user_schema"; return 1; }    
    committed_schema="${_db_committed_schema_dir}/${base}"

    # If committed schema exists, detect drift vs user schema
    if [[ -f "$committed_schema" ]]; then
        _db_schema_drift_detected_nolock "$user_schema"
        case $? in
            0) : ;; # ok
            1) _db_set_error "Schema drift detected for ${base}. Use reset/migration path."; return 1 ;;
            *) _db_add_error_ctx; return 1 ;;
        esac

        # Ensure table/sequences based on committed schema (not user schema)
        _db_create_table_from_committed_schema_nolock "$committed_schema" || { _db_add_error_ctx; return 1; }
        return 0
    fi

    # No committed schema yet: stage it first
    staged="$(_db_stage_schema_file_nolock "$user_schema")" || { _db_add_error_ctx; return 1; }
        
    # Create table/sequences from staged schema (atomic)
    _db_create_table_from_committed_schema_nolock "$staged" || {
        rm -f "$staged" >/dev/null 2>&1 || true
        _db_add_error_ctx
        return 1
    }
    
    # Commit schema snapshot ONLY after successful create
    _db_commit_staged_schema_nolock "$staged" "$user_schema" || { _db_add_error_ctx; return 1; }
    
    return 0
}


_db_init_db_nolock() {
    # WARN: not thread safe; must be called under meta lock via _db_execute_with_lock
    local dir
    local dirty_dirs=()
    
    # Defensive safety guards
    # check _db_lock_is_held flag & check private config state is set
    _db_is_lock_held || { _db_add_error_ctx; return 1; }
    _db_is_config_set || { _db_add_error_ctx; return 1; }
  
    # Idempotent under lock: marker means committed init
    _db_is_init && return 0

    # create base directories if missing; track only those created by this call
    {
        [[ -d "${_db_tables_dir}" ]] || { mkdir "${_db_tables_dir}" && dirty_dirs+=("${_db_tables_dir}"); } &&
        [[ -d "${_db_seq_dir}" ]] || { mkdir "${_db_seq_dir}" && dirty_dirs+=("${_db_seq_dir}"); } &&
        [[ -d "${_db_locks_dir}" ]] ||  { mkdir "${_db_locks_dir}" && dirty_dirs+=("${_db_locks_dir}"); } &&
        [[ -d "${_db_tmp_dir}" ]] ||  { mkdir "${_db_tmp_dir}" && dirty_dirs+=("${_db_tmp_dir}"); } &&
        [[ -d "${_db_meta_dir}" ]] ||  { mkdir "${_db_meta_dir}" && dirty_dirs+=("${_db_meta_dir}"); } &&
        [[ -d "${_db_committed_schema_dir}" ]] ||  { mkdir "${_db_committed_schema_dir}" && dirty_dirs+=("${_db_committed_schema_dir}"); } &&
        # Commit marker (atomic). Note: relies on _db_tmp_dir existing (created above if needed)
        _db_create_file_atomic_nolock "$_db_init_marker" '1.0'
    } || {
         
        _db_set_error "Failed to create db directories. Rolling back (best effort)"

        # best effort directory rollback, in reverse order
        for ((i=${#dirty_dirs[@]}-1; i>=0; i--)); do
            dir="${dirty_dirs[i]}"
            rmdir "$dir" 2>/dev/null || true
        done     
        return 1
    }
}


_db_init_schema_nolock() {
    # WARN: not thread safe; must be called under meta lock via _db_execute_with_lock
    local schema_dir="${1:-}"
    local schema_file
    local -a table_schemas=()

    # Defensive safety guards
    # check _db_lock_is_held flag & check private config state is set
    _db_is_lock_held || { _db_add_error_ctx; return 1; }
    _db_is_config_set || { _db_add_error_ctx; return 1; }

    [[ -n "$schema_dir" ]] || { _db_set_error "No schema directory provided"; return 1; } 
    [[ -d "$schema_dir" ]] || { _db_set_error "$schema_dir is not a directory"; return 1; }

    # Ensure base DB exists first (call under same lock)
    _db_init_db_nolock || return 1

    # Idempotent check
    _db_schema_is_init && return 0

    # Create schema

    # --- find user defined schema files
    shopt -s nullglob
    table_schemas=( "${schema_dir}"/*.schema )
    shopt -u nullglob

    # --- guard: check schema files exist
    if [[ "${#table_schemas[@]}" -eq 0 ]]; then
        _db_set_error "No table schemas found in ${schema_dir}"
        return 1
    fi  

    # --- create tables and associated sequences (under same lock)
    for schema_file in "${table_schemas[@]}"; do
        # _db_create_table_from_schema_nolock is atomic under lock
        _db_create_table_from_user_schema_nolock "$schema_file" || { _db_add_error_ctx; return 1; }
    done

    _db_create_file_atomic_nolock "$_db_schema_init_marker" '1.0' || { _db_add_error_ctx; return 1; }

    return 0  
}


# Lock acquisition wrappers
_db_with_global_lock_exclusive() {
    # Usage: _db_with_global_lock_exclusive <fn> [args...]
    local fn="${1:-}"
    shift || true

    [[ -n "$fn" ]] || { _db_set_error "Missing function"; return 1; }
    _db_is_config_set || return 1

    local lockfile="${_db_root}/.meta.lock"
    local rc=0

    # Save existing traps (so we can restore them)
    local _old_return_trap _old_int_trap _old_term_trap
    _old_return_trap="$(trap -p RETURN)"
    _old_int_trap="$(trap -p INT)"
    _old_term_trap="$(trap -p TERM)"

    # Install temporary trap that ALSO restores old traps
    trap '_db_lock_held=0; exec 200>&- 2>/dev/null || true; eval "$_old_return_trap"; eval "$_old_int_trap"; eval "$_old_term_trap"' RETURN INT TERM

    # ---- acquire lock -----
    exec 200>>"$lockfile" || { _db_set_error "Open meta lock failed: $lockfile"; return 1; }
    flock -w 30 -x 200 || { _db_set_error "Acquire meta lock failed: $lockfile"; return 1; }
    
    _db_lock_held=1

    # ---- run wrapped function -----
    "$fn" "$@"
    rc=$?

    # Return wrapped function return code (temporary trap will run and cleanup/restore old traps)
    return "$rc"
}

_db_with_table_lock() {
    # Usage: _db_with_table_lock <table> <fn> [args...]
    local table="${1:-}"
    local fn="${2:-}"
    shift 2 || true

    [[ -n "$table" && -n "$fn" ]] || { _db_set_error "Bad usage"; return 1; }
    _db_is_config_set || return 1

    local meta_lock="${_db_root}/.meta.lock"
    local table_lock="${_db_locks_dir}/${table}.lock"
    local table_file="${_db_tables_dir}/${table}.tbl"
    local rc=0

    # Save existing traps (so we can restore them)
    local _old_return_trap _old_int_trap _old_term_trap
    _old_return_trap="$(trap -p RETURN)"
    _old_int_trap="$(trap -p INT)"
    _old_term_trap="$(trap -p TERM)"

    # Temp trap closes BOTH FDs and restores old traps
    trap '_db_lock_held=0; exec 201>&- 2>/dev/null || true; exec 200>&- 2>/dev/null || true; eval "$_old_return_trap"; eval "$_old_int_trap"; eval "$_old_term_trap"' RETURN INT TERM

    # 1) Acquire global lock in SHARED mode (blocks init/migrations)
    exec 200>>"$meta_lock" || { _db_set_error "Open meta lock failed: $meta_lock"; return 1; }
    flock -w 30 -s 200 || { _db_set_error "Acquire meta shared lock failed: $meta_lock"; return 1; }

    # Validate existence of table/table lock under meta lock
    [[ -f "${table_file}" && -f "${table_lock}" ]] || { _db_set_error "Table '$table' does not exist"; return 1; }

    # 2) Acquire table lock in EXCLUSIVE mode
    exec 201>>"$table_lock" || { _db_set_error "Open table lock failed: $table_lock"; return 1; }
    flock -w 30 -x 201 || { _db_set_error "Acquire table lock failed: $table_lock"; return 1; }

    _db_lock_held=1

    # ---- run wrapped function
    "$fn" "$@"
    rc=$?

    # Return wrapped function return code (temporary trap will run and cleanup/restore old traps)
    return "$rc"
}


# -----------------------------------------------------------------------------
# Public API
# -----------------------------------------------------------------------------
db_last_error() {
    # Prints last error message
    printf '%s\n' "${_db_err_msg}"
}

db_last_error_context() {
    # Optional extra info (e.g. captured OS error output)
    printf '%s\n' "${_db_err_ctx}"
}

db_init_db() {
    # Usage: db_init_db <DB_DIR>
    local db_dir="${1:-}"

    [[ -n "${db_dir}" ]] || { _db_set_error "Bad usage; no DB_DIR provided"; return 1; }

    _db_clear_error
    _db_bootstrap_db_config "${db_dir}" || return 1

    # Ensure root exists so lockfile can exist
    mkdir -p "${_db_root}" || { _db_set_error "Error creating database root directory $db_dir"; return 1; }
    
    # execute critical section of DB initialise with global exclusive global db lock
    _db_with_global_lock_exclusive _db_init_db_nolock
}

db_init_schema() {
    # Usage: db_init_schema <DB_DIR> <SCHEMA_DIR>
    local db_dir="${1:-}"
    local schema_dir="${2:-}"

    [[ -n "${db_dir}" && -n "$schema_dir" ]] || { _db_set_error "Bad usage; DB_DIR and SCHEMA_DIR expected"; return 1; }

    _db_clear_error
    _db_bootstrap_db_config "${db_dir}" || return 1
    
    # Ensure root exists so lockfile can exist
    mkdir -p "${_db_root}" || { _db_set_error "Error creating database root directory $db_dir"; return 1; }

    # execute critical section with schema lock
    _db_with_global_lock_exclusive _db_init_schema_nolock "$schema_dir"
}




#db_select() {}

#db_insert() {}

#db_update() {}

#db_delete() {}
