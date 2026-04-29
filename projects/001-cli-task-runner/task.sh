#!/usr/bin/env bash
set -eou pipefail

# =========================================================================
# Config / Constants
# =========================================================================
SCRIPT_DIR=$(cd -- "$(dirname "${BASH_SOURCE[0]}")" && pwd)
DATA_DIR="$SCRIPT_DIR/data"
LOG_DIR="SCRIPT_DIR/logs"

# =========================================================================
# Utility Functions
# =========================================================================
#log() {}



# =========================================================================
# CLI Layer (parse + route)
# =========================================================================

# parse args
# validate shape
# route to a BLL handler
# print final output + exit codes


# =========================================================================
# Business Logic Layer (Validation + Biz. Rules)
# =========================================================================
#task_add() {
    # description must be a non-zero length string
#}

#task_get() {

#}

#task_done() {
    # task ID must exist
    # task must not be deleted, deleted tasks are locked for modification
    # operation is idempotent if task is already done, do not fail, return silently
#}

#task_delete() {}

#task_list() {
    # sort based on status and by task ID within status 
    # eg OPEN, IN PROGRESS, DONE, and the alphabetically within each Status Group

#}



# =========================================================================
# Storage Layer
# =========================================================================
_db_is_init() {
    # check if DB exists/has been initialised
    # TODO : implement this, returns false by default for initial dev
    echo INFO "_db_is_init: database is not initialised"
    return 1
}

_db_init_dirs() {
    if [[ -z "$DATA_DIR" || ! -d "$DATA_DIR" ]]; then
        echo ERROR "_db_init: '$DATA_DIR' is not a valid directory"
        return 1
    fi

    echo INFO '_db_init: intialising db'

    local db_dir="${DATA_DIR}/db"
    local table_dir="${db_dir}/tables"
    local seq_dir="${db_dir}/seq"
    local locks_dir="${db_dir}/locks"
    local tmp_dir="${db_dir}/tmp"
    local dirs=($db_dir $table_dir $seq_dir $locks_dir $tmp_dir)
    local output

    for dir in "${dirs[@]}"; do
        echo INFO "_db_init_dirs: creating database directory $dir"
        if ! output=$(mkdir "$dir" 2>&1); then
            echo ERROR "_db_init_dirs: error creating database directory $dir"
            echo ERROR "OS Error: $output"
            return 1
        fi
    done
    return 0
}

_db_init_schema() {
    local table_dir="${DATA_DIR}/db/tables"
    local seq_dir="${DATA_DIR}/db/seq"
    local output

    if [[ ! -d "$table_dir" ]]; then
        echo ERROR "_db_init_schema: tables/ directory $table_dir not found"
        return 1
    fi

    if [[ ! -d "$seq_dir" ]]; then
        echo ERROR "_db_init_schema: seq/ directory $seq_dir not found"
        return 1
    fi

    echo INFO "_db_init_schema: initialising tasks schema"

    local table_file="${table_dir}/tasks.tbl"
    local seq_fil="${seq_dir}/tasks_id.seq"

    if ! output=$(touch "$table_file" 2>&1); then
        echo ERROR "_db_init_schema: error initialisting table $table_file"
        echo ERROR "OS Error: $output"
        return 1
    fi

    local header="TASK_ID|DESCRIPTION|STATUS|VERSION"
    echo $header >> $table_file


}



_db_init()  {
    if _db_is_init; then
        echo INFO '_db_init: db is initialised'
        return 0
    fi

    _db_init_dirs
    _db_init_schema
}



#_db_next_id() {}


#db_select_task_by_id() {}


#db_select_tasks_by_status() {}

#db_insert_task() {}






# =========================================================================
# Main
# =========================================================================

# parse args
# validate command
# route args to BBL command handler
# command handler should do enforce BBL (where does validation happen?? should probably happen early)



# Logicall for select I want:
# check if table exists
# if table exists:
# get the header row (column names)
# if ID exists get just that record
# if no ID, get all records

_db_init