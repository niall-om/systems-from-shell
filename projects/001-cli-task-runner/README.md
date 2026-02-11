### Project - CLI Task Runner


#### 1) 🎯 Overview

Build a command-line task management system in Bash that supports creating, listing, updating, and deleting tasks.

The system should treat tasks as durable state stored in a flat file and explicitly model task lifecycle transitions. The goal is not just to build a todo app, but to practice:

- Command parsing
- State modeling
- Data persistence
- Idempotency
- Safe file updates
- Separation of concerns in shell scripts

This project establishes foundational patterns you will reuse in all later system projects.


#### 2) ✅ Functional Requirements

##### Core Commands

The CLI must support:

`./task.sh add "Task description"`  
`./task.sh list`  
`./task.sh done <task_id>`  
`./task.sh delete <task_id>`  
`./task.sh help`

##### Task Model

Each task must contain:

- Unique ID (incremental integer or UUID)
- Description
- Status (open / done)
- Created timestamp
- Completed timestamp (if applicable)

##### Behavior Requirements

- `add` creates a new task with status "open"
- `list` displays all tasks in a human-readable format
- `done` marks a task as completed
- `delete` removes a task safely
- The system must persist tasks across script runs
- Invalid IDs must return clear error messages
- Duplicate IDs must never occur
- Tasks must maintain consistent state transitions (no invalid status changes)


#### 3) ⚙️ Non-Functional Requirements

- **Durability:** No data loss if the script crashes mid-operation
- **Atomicity:** Updates must not corrupt the task file (use safe write patterns)
- **Idempotency:** Re-running commands should not cause inconsistent state
- **Portability:** Use POSIX-compatible shell where possible
- **Minimal dependencies:** Bash + standard coreutils only
- **Human-readable data format**
- **Clear error messaging**
- **Defensive scripting:** Validate input and fail safely

Optional stretch:

- Safe concurrent reads (no need to support concurrent writes yet)


#### 4) ▶️ How It Should Be Run

##### Setup

Make the script executable:

`chmod +x task.sh`

##### Example Usage

`./task.sh add "Write documentation"`  
`./task.sh list`  
`./task.sh done 1`  
`./task.sh delete 2`

##### Data Storage

All task state must be stored in:

`./data/tasks.db`

The script must create the `data` directory if it does not exist.


#### 5) 📦 Expected Outcomes

After implementation, the system should demonstrate:

- Clear CLI argument parsing
- Clean separation between:
  - CLI interface layer
  - Business logic layer
  - Storage layer
- Stable flat-file persistence
- Robust error handling
- Well-formatted, readable output
- Clear documentation of the file format used

The internal structure of the script should be understandable and modular.


#### 6) 🧠 System Design Concepts Practiced

This project intentionally exercises:

- State machine modeling (task lifecycle)
- Append-only logs vs full rewrites
- Atomic file updates (write → temp file → move)
- Separation of concerns in scripting
- CLI UX design
- Data modeling in constrained environments
- Defensive scripting practices
- Explicit state transitions

This is your foundational project. Later systems will reuse these patterns extensively.