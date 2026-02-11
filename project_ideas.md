# A list of project ideas for exploring system design with Shell

This is a list of project ideas to explore fundamental system design concepts using on the shell. 

Why Shell?

Shell forces you to think in:
- Processess as independent actors
- Files as durable state
- Signals as control messages
- Pipes as streaming interfaces
- The OS as a distributed system kernel


## 📚 Project Index

- [1️⃣ CLI Task Runner](#1️⃣-cli-task-runner)
- [2️⃣ Log Processor Pipeline](#2️⃣-log-processor-pipeline)
- [3️⃣ Basic Job Queue (Single Worker)](#3️⃣-basic-job-queue-single-worker)
- [4️⃣ Multi-Worker Queue (Race Condition Exploration)](#4️⃣-multi-worker-queue-race-condition-exploration)
- [5️⃣ Producer Consumer with Backpressure](#5️⃣-producer-consumer-with-backpressure)
- [6️⃣ Rate Limiter](#6️⃣-rate-limiter)
- [7️⃣ Supervisor / Process Monitor](#7️⃣-supervisor--process-monitor)
- [8️⃣ Retry with Dead Letter Queue](#8️⃣-retry-with-dead-letter-queue)
- [9️⃣ Idempotent Deployment Script](#9️⃣-idempotent-deployment-script)
- [🔟 Leader Election (File-Based)](#🔟-leader-election-file-based)
- [1️⃣1️⃣ Log Replication Simulator](#1️⃣1️⃣-log-replication-simulator)
- [1️⃣2️⃣ Circuit Breaker](#1️⃣2️⃣-circuit-breaker)
- [1️⃣3️⃣ Mini Cron](#1️⃣3️⃣-mini-cron)
- [1️⃣4️⃣ Mini systemd (Service Manager)](#1️⃣4️⃣-mini-systemd-service-manager)
- [1️⃣5️⃣ Simple HTTP Server Using netcat (nc)](#1️⃣5️⃣-simple-http-server-using-netcat-nc)
- [1️⃣6️⃣ Metrics Collector Exposing /metrics](#1️⃣6️⃣-metrics-collector-exposing-metrics)
- [1️⃣7️⃣ Shell-Based Event Bus Using Named Pipes (FIFOs)](#1️⃣7️⃣-shell-based-event-bus-using-named-pipes-fifos)



## Level 1 - Processing Thinking (Fundamentals)

### 1️⃣ CLI Task Runner


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


---

### 2️⃣ Log Processor Pipeline

#### 1) 🎯 Overview

Build a streaming log processing pipeline using shell tools (and/or a small Bash wrapper) that can ingest logs in real time, filter and transform events, and produce rolling summaries and alerts.

This project is about practicing “UNIX pipeline as a system” thinking:
- data flows through processes
- each stage is simple and composable
- the pipeline is observable and restartable
- stateful aggregation is handled intentionally (not accidentally)

You’ll implement an end-to-end pipeline that can run continuously against a log file (or a simulated log generator).

#### 2) ✅ Functional Requirements

##### Log Input

The pipeline must support at least one real-time input mode:

- Follow a file as it grows (tailing):
  - Input source: `./data/app.log` (or configurable)
  - Must process new lines as they are appended

Optional stretch:
- Support reading from STDIN as an alternative input mode

##### Log Format Assumptions

Assume logs are line-based text. You may choose a simple format such as:

- Timestamp, level, component, message (space or JSON lines)
- Example levels: INFO, WARN, ERROR

The pipeline must be robust to occasional malformed lines:
- malformed lines should be counted and skipped (not crash the pipeline)

##### Processing Stages

Implement the pipeline with clear stages (can be separate scripts or clearly separated functions):

1. Parse stage:
   - Extract fields (at minimum: timestamp and severity/level)
   - Tag malformed lines

2. Filter stage:
   - Support filtering by level:
     - e.g. only ERROR and WARN
   - Support filtering by component (optional)

3. Transform/enrich stage:
   - Add derived fields such as:
     - normalized level
     - day/minute bucket (for aggregation)

4. Aggregation stage (rolling summary):
   - Produce counts per level over a time window (e.g. last 60 seconds)
   - Also produce top-N message patterns or components (optional)

5. Output stage:
   - Write rolling summaries to a file:
     - `./out/summary.log`
   - Write alert events (e.g. “ERROR spike detected”) to:
     - `./out/alerts.log`

##### Alerting

Implement at least one alert rule, for example:
- If ERROR count in the last 60 seconds exceeds threshold T, emit an alert line

Alerts must:
- include timestamp
- include threshold and observed value
- be appended to an alerts log

##### Controls / Commands

At minimum, support:

- Start pipeline:
  - `./run_pipeline.sh`
- Stop pipeline cleanly (Ctrl+C should terminate child processes cleanly)

Optional stretch:
- Support `./run_pipeline.sh --level ERROR --window 60 --threshold 10`


#### 3) ⚙️ Non-Functional Requirements

- **Streaming:** Must process input incrementally (no “read entire file then process”)
- **Composability:** Prefer small steps connected with pipes
- **Resilience:** Pipeline should tolerate malformed lines without exiting
- **Observability:** Must write clear logs/metrics about its own behavior (counts processed, malformed, etc.)
- **Restartability:** Restarting the pipeline should not corrupt outputs (append or rotate safely)
- **Resource efficiency:** Should not grow memory unbounded (aggregation window must be bounded)
- **Portability:** Use Bash + standard UNIX tools (grep/sed/awk/cut/tail/sort/uniq/date). Avoid heavy dependencies.


#### 4) ▶️ How It Should Be Run

##### Setup

Create directories:

- `./data/` (input logs)
- `./out/` (outputs)

Optionally include a log generator to simulate production logs:

- `./gen_logs.sh` (writes lines into `./data/app.log` continuously)

##### Typical Run

1) Start log generator (optional, in one terminal):

- `./gen_logs.sh`

2) Start pipeline (second terminal):

- `./run_pipeline.sh`

##### Outputs

- Rolling summaries written to:
  - `./out/summary.log`
- Alerts written to:
  - `./out/alerts.log`

Optional:
- A pipeline internal stats file:
  - `./out/pipeline_stats.log`

Stopping:
- Ctrl+C should stop the pipeline and terminate any spawned subprocesses cleanly.


#### 5) 📦 Expected Outcomes

By the end, you should have:

- A working streaming pipeline that:
  - follows a live log file
  - filters and transforms events
  - maintains rolling aggregates
  - emits alerts based on thresholds
- A clear staged architecture (even if implemented in one script)
- Documentation explaining:
  - expected input format
  - alert rules
  - how rolling window aggregation is implemented
  - how to run and stop the system

This should feel like a mini “observability pipeline” built from first principles.


#### 6) 🧠 System Design Concepts Practiced

- Streaming processing vs batch processing
- Pipelines as systems: stages, contracts, interfaces
- Backpressure (conceptually) and throughput limits (pipeline bottlenecks)
- Stateless vs stateful stages (aggregation introduces state)
- Windowed aggregation (bounded memory/time windows)
- Fault tolerance for malformed/dirty input
- Observability: instrumentation for your instrumentation
- Operational concerns: start/stop behavior, logs, reproducibility


---

### 3️⃣ Basic Job Queue (Single Worker)


#### 1) 🎯 Overview

Build a simple, reliable, file-based job queue where “jobs” are represented as files placed into a queue directory. A single worker process continuously polls the queue, claims jobs, executes them, and records outcomes.

This project is about practicing:
- queue semantics using the filesystem as the broker
- atomic job claiming (so a job is never processed twice)
- lifecycle states (queued → processing → done/failed)
- durable logs and repeatable operation

You will intentionally keep it single-worker to simplify concurrency, then later evolve this design in Project 4.


#### 2) ✅ Functional Requirements

##### Directory-Based Queue Structure

The system must use a clear job lifecycle directory structure:

- `./queue/`         (new jobs arrive here)
- `./processing/`    (jobs currently being worked on)
- `./done/`          (successfully completed jobs)
- `./failed/`        (failed jobs)
- `./logs/`          (worker logs, optional but recommended)

The system must create these directories if missing.

##### Job Definition

Each job must be representable as a file. Choose one of these job formats:

Option A (command file):
- A file containing a shell command (or small script) to execute

Option B (JSON-ish or key=value payload):
- A payload file that your worker interprets (e.g., type=… args=…)

Pick one and document it.

Each job file must have:
- a unique filename (job ID)
- contents describing what to do

##### Worker Behavior

A worker script (e.g. `./worker.sh`) must:

- Run continuously until stopped
- Poll `./queue/` for jobs
- Claim exactly one job at a time
- Move claimed job into `./processing/` (atomic move)
- Execute the job
- On success:
  - move job file to `./done/`
- On failure:
  - move job file to `./failed/`
- Log each transition with timestamps

##### Command-Line Interface

At minimum:

- Start worker:
  - `./worker.sh`
- Add a job:
  - via a helper script `./enqueue.sh` OR manual file creation documented in README

Optional stretch:
- `./enqueue.sh --cmd "echo hello"`
- `./enqueue.sh --file path/to/job.payload`
- `./worker.sh --once` (process one job then exit)

##### Job Execution Result

For each job, store an execution result record:

- exit code
- start time / end time
- captured stdout/stderr (optional but recommended)

Store results in a per-job output file or a central log file.


#### 3) ⚙️ Non-Functional Requirements

- **Atomicity:** Job claiming must be atomic (use `mv` from queue → processing)
- **Exactly-once processing (single worker):** No job should be processed twice
- **Durability:** State survives restarts (jobs remain in directories)
- **Crash tolerance:** If worker crashes mid-job, job should not vanish
  - acceptable behavior: job remains in `processing/` and can be re-queued manually or by a recovery step (optional)
- **Observability:** Clear logs with timestamps and job IDs
- **Simplicity:** Minimal dependencies (bash + coreutils)
- **Idempotency guidance:** Document that jobs should ideally be idempotent, and why

Optional stretch:
- Add a “requeue” command for jobs stuck in processing
- Add a maximum runtime / timeout per job


#### 4) ▶️ How It Should Be Run

##### Setup

Create directories (or let scripts create them):

- `queue/`
- `processing/`
- `done/`
- `failed/`
- `logs/` (optional)

Make scripts executable:

- `chmod +x worker.sh enqueue.sh` (if enqueue.sh exists)

##### Run the Worker

Start the worker:

- `./worker.sh`

Stop the worker:

- Ctrl+C (should stop cleanly)

##### Enqueue a Job (Examples)

Example A (command job file created manually):

- Create a job file:
  - Put a command in `queue/job-001.cmd` (e.g. `echo hello`)
- Worker should pick it up and process it

Example B (using helper script, if you implement it):

- `./enqueue.sh "echo hello"`

##### Verify Outputs

- Completed jobs appear in `done/`
- Failed jobs appear in `failed/`
- Logs show job lifecycle transitions
- Optional: per-job output files stored in `done/` or `logs/`


#### 5) 📦 Expected Outcomes

You should end up with:

- A working single-worker job processing system
- A clean state model encoded by directories
- Atomic job claiming via filesystem operations
- Transparent logs and predictable behavior on restart
- Documentation explaining:
  - job format
  - lifecycle directories
  - how to enqueue jobs
  - how failures are handled
  - what happens if the worker crashes

This becomes the foundation for multi-worker coordination, retries, and reliability patterns.


#### 6) 🧠 System Design Concepts Practiced

- Queue abstraction using filesystem primitives
- State machines and job lifecycle modeling
- Atomic “claim” semantics (move as a lock/claim)
- Durable state and restart behavior
- Separation of concerns:
  - enqueuing
  - claiming
  - execution
  - recording outcomes
- Observability via logs and artifacts
- Reliability basics (what does “job lost” mean?)


---


## Level 2 - Concurrency & Coordination
---


### 4️⃣ Multi-Worker Queue (Race Condition Exploration)

#### 1) 🎯 Overview

Extend the Basic Job Queue (Project 3) to support multiple concurrent workers safely.

You will now run multiple worker processes simultaneously, all competing for jobs from the same `queue/` directory. The goal is to explore:

- Race conditions
- Mutual exclusion
- Atomic operations
- Coordination without shared memory
- Failure scenarios in concurrent systems

This project intentionally forces you to think about concurrency using only filesystem primitives and shell tools.


#### 2) ✅ Functional Requirements

##### Multi-Worker Support

The system must:

- Support running 2+ workers concurrently
- Ensure that each job is processed exactly once
- Prevent two workers from claiming the same job

You should be able to run:

`./worker.sh &`  
`./worker.sh &`  
`./worker.sh &`

All workers must cooperate safely.

##### Atomic Job Claiming

When a worker attempts to process a job:

- It must atomically claim it
- It must not allow another worker to claim the same job
- Claiming must not rely on naive checks like:
  - “if file exists, then process”

You must use one of:

- Atomic `mv` operations
- `flock`
- Lock files
- Or another robust mechanism (document your choice)

##### Worker Identity

Each worker must:

- Have a unique worker ID (PID is acceptable)
- Log its ID with each job it processes

Example log entry:

`[timestamp] worker=12345 claimed job=job-001`

##### Failure Handling

If a worker crashes while processing a job:

- The job must not disappear
- It must remain in `processing/`
- You must document recovery behavior

Optional stretch:
- Add a recovery mechanism that re-queues stale jobs from `processing/`


#### 3) ⚙️ Non-Functional Requirements

- **Concurrency Safety:** No job processed more than once
- **Atomicity:** Claim operations must be atomic
- **Durability:** No job loss across restarts
- **Observability:** Logs clearly show which worker handled each job
- **Scalability (basic):** Should work with at least 10+ jobs queued
- **No Busy Spinning:** Avoid tight infinite loops consuming CPU
- **Minimal Dependencies:** Bash + coreutils only

Optional stretch:
- Add a small sleep/backoff when no jobs are available


#### 4) ▶️ How It Should Be Run

##### Setup

Ensure directory structure exists:

- `queue/`
- `processing/`
- `done/`
- `failed/`
- `logs/`

##### Start Multiple Workers

In separate terminals or background:

`./worker.sh &`  
`./worker.sh &`  
`./worker.sh &`

##### Enqueue Jobs

Use the enqueue mechanism from Project 3:

`./enqueue.sh "echo hello"`

Or manually create job files in `queue/`.

##### Verify Behavior

- Each job appears only once in `done/` or `failed/`
- Logs show different worker IDs processing different jobs
- No job appears in both `done/` and `failed/`
- No duplicate execution occurs

Stop workers using:

`kill <pid>` or Ctrl+C (if running in foreground)


#### 5) 📦 Expected Outcomes

By completion, you should have:

- A safe multi-worker job queue
- Clear evidence that jobs are not duplicated
- Logs showing worker coordination
- A documented strategy for atomic job claiming
- Understanding of how race conditions manifest and how they are prevented

You should also be able to intentionally break naive implementations to see race conditions occur (recommended learning exercise).


#### 6) 🧠 System Design Concepts Practiced

- Race conditions
- Mutual exclusion
- Locking strategies
- Atomic filesystem operations
- Coordination without shared memory
- Crash recovery implications
- Observability in concurrent systems
- Backoff and polling design

This is your first real concurrency system.


---

### 5️⃣ Producer–Consumer with Backpressure

#### 1) 🎯 Overview

Build a producer–consumer system in Bash where one process generates jobs and one or more worker processes consume them — with a bounded queue and backpressure.

Unlike previous queue projects, this system must:

- Limit the size of the queue
- Prevent unbounded job accumulation
- Block or slow the producer when the queue is full

This project introduces flow control — a core systems design concept — and forces you to think about throughput, capacity, and system stability.


#### 2) ✅ Functional Requirements

##### System Roles

You must implement:

- A **Producer** process
- One or more **Consumer** processes (workers)
- A bounded queue directory

##### Queue Capacity

Define a maximum queue size (e.g. 10 jobs).

When the queue reaches capacity:

- The producer must not continue producing indefinitely.
- The producer must either:
  - Block until space is available, OR
  - Sleep and retry, OR
  - Exit with a clear error (choose and document behavior).

##### Producer Behavior

The producer must:

- Generate jobs at a configurable rate
- Write jobs into `./queue/`
- Respect queue capacity limits
- Log when backpressure is triggered

Example run:

`./producer.sh --rate 2`  (2 jobs per second)

Optional:
- Allow `--max-jobs N`

##### Consumer Behavior

Consumers must:

- Poll the queue
- Atomically claim jobs
- Process jobs
- Move them to `done/` or `failed/`
- Log processing duration

Consumers may be reused from Project 4 (multi-worker queue).

##### Observability

You must log:

- When producer blocks due to full queue
- Current queue size
- Jobs processed per minute (optional stretch)



#### 3) ⚙️ Non-Functional Requirements

- **Bounded Memory:** Queue size must not grow unbounded
- **Flow Control:** Producer must respond to system pressure
- **Concurrency Safety:** No job duplication
- **Stability:** System should remain stable under sustained load
- **Graceful Shutdown:** Ctrl+C should terminate cleanly
- **Minimal Dependencies:** Bash + coreutils only
- **Low CPU Waste:** Avoid tight polling loops

Optional stretch:
- Implement dynamic rate adjustment based on queue size



#### 4) ▶️ How It Should Be Run

##### Setup

Ensure directory structure exists:

- `queue/`
- `processing/`
- `done/`
- `failed/`
- `logs/`

##### Start Consumers

`./worker.sh &`  
`./worker.sh &`

##### Start Producer

`./producer.sh --rate 5`

This should:

- Generate 5 jobs per second
- Stop or block when queue reaches max size
- Resume when consumers free capacity

##### Verify Behavior

- Queue size never exceeds configured limit
- Producer logs when backpressure activates
- Consumers steadily drain queue
- System stabilizes at equilibrium under sustained load



#### 5) 📦 Expected Outcomes

By the end, you should have:

- A bounded queue implementation
- A working producer respecting capacity limits
- Stable multi-process system under load
- Clear logs showing:
  - Queue size changes
  - Producer blocking/resuming
  - Consumer throughput

You should be able to simulate:

- Fast producer + slow consumers (queue fills)
- Slow producer + fast consumers (queue empty)
- Balanced steady-state system



#### 6) 🧠 System Design Concepts Practiced

- Producer–consumer pattern
- Backpressure and flow control
- Bounded queues
- Throughput vs latency tradeoffs
- System equilibrium
- Stability under load
- Resource protection
- Capacity planning fundamentals

This is your first real performance-aware system.


---


### 6️⃣ Rate Limiter

#### 1) 🎯 Overview

Build a rate limiter in Bash that controls how often an operation (a command) is allowed to run. The limiter must enforce a maximum rate such as:

- N operations per second, or
- N operations per minute

This project teaches you how to design time-based control systems with durable state, and how to make them safe under concurrency (multiple processes trying to consume rate-limited capacity at the same time).

You will implement a reusable wrapper that can be placed in front of other scripts/commands.


#### 2) ✅ Functional Requirements

##### Primary Capability

Provide a wrapper that runs a command only if allowed by the rate limit:

`./rate_limit.sh --limit 10 --window 60 -- ./some_command.sh arg1 arg2`

Meaning:
- allow at most 10 executions per 60 seconds

If the command is not allowed, the limiter must either:
- block until allowed (default recommended), OR
- exit with a non-zero code and clear message

Pick one default behavior and document it. Optionally support both via a flag.

##### Supported Algorithms

Implement at least one of:

- Fixed window counter (simplest)
- Sliding window (harder)
- Token bucket (recommended balance)
- Leaky bucket

Choose one and document the algorithm clearly.

##### Persistence

The limiter must persist state in a file so it survives restarts:

- `./data/rate_limit.state` (default, configurable)

State must include enough information to enforce limits correctly across script restarts.

##### Concurrency Safety

If multiple processes call the limiter concurrently, it must still enforce the limit correctly. You must implement safe coordination using one of:

- `flock`
- atomic file operations
- lock directory (`mkdir` as lock)
- another robust technique (document choice)

##### Exit Codes

Define clear exit codes, for example:
- 0: command ran successfully
- 1: rate limited (if in non-blocking mode)
- 2: usage/config error
- 3: underlying command failed (propagate or wrap)

Document your chosen scheme.


#### 3) ⚙️ Non-Functional Requirements

- **Correctness:** Never exceed the configured rate under concurrent use
- **Durability:** State file must not be corrupted on crash/interruption
- **Atomicity:** State updates must be atomic
- **Observability:** Optional logs showing allow/deny decisions and timestamps
- **Portability:** Bash + coreutils only (avoid nonstandard date features if possible)
- **Performance:** Should handle frequent calls without excessive CPU use
- **Configurability:** Support parameters via CLI flags (limit/window/state path)

Optional stretch:
- Support multiple independent keys (per “user” / per “job type”) using separate state files or key-based state


#### 4) ▶️ How It Should Be Run

##### Setup

Create a data directory for state:

- `./data/`

Make executable:

- `chmod +x rate_limit.sh`

##### Example Runs

Blocking mode (recommended default):

`./rate_limit.sh --limit 5 --window 10 -- ./do_work.sh`

Non-blocking mode (optional):

`./rate_limit.sh --limit 5 --window 10 --non-blocking -- ./do_work.sh`

Concurrency test (run these quickly in separate terminals):

- `./rate_limit.sh --limit 2 --window 5 -- echo "A"`
- `./rate_limit.sh --limit 2 --window 5 -- echo "B"`
- `./rate_limit.sh --limit 2 --window 5 -- echo "C"`

Expected: only 2 run immediately; the 3rd blocks (or fails) depending on mode.



#### 5) 📦 Expected Outcomes

You should end up with:

- A reusable rate-limiting wrapper script
- A clearly documented algorithm and state format
- A persistent state file that survives restarts
- Concurrency-safe enforcement (no bursts beyond limit due to races)
- A simple test harness or instructions to validate behavior

You should be able to answer confidently:
- “What happens if 10 processes call this at the same time?”
- “What happens if the script crashes mid-update?”
- “What guarantees does this rate limiter provide?”



#### 6) 🧠 System Design Concepts Practiced

- Time-based state and control
- Resource governance (rate control)
- Concurrency coordination (locking)
- Durable state under contention
- Backpressure design (block vs fail-fast)
- Correctness vs simplicity tradeoffs in algorithm choice
- Operational testing under load

---


## Level 3 - Reliability Patterns
---

### 7️⃣ Supervisor / Process Monitor

#### 1) 🎯 Overview

Build a simple process supervisor in Bash that launches a target program (e.g., your worker from Projects 3–5), monitors it, and restarts it if it crashes.

This project is about practicing reliability patterns commonly found in real systems (systemd, supervisord, Kubernetes restart policies):

- crash detection
- restart policies
- backoff strategies
- avoiding restart storms
- signal handling and graceful shutdown

You will implement a reusable supervisor script that can supervise any command.



#### 2) ✅ Functional Requirements

##### Launch and Monitor

The supervisor must:

- Start understanding what command to run (target program + args)
- Launch the target as a child process
- Record the child PID
- Detect if/when the child exits
- Capture the child’s exit code
- Restart the child based on policy

Example:

`./supervisor.sh -- ./worker.sh --arg value`

##### Restart Policy

Must support:

- Restart on non-zero exit code (crash)
- Optional: restart always (even on clean exit)
- Optional: never restart (one-shot monitoring)

At minimum, implement restart-on-failure.

##### Backoff and Limits

To prevent restart storms, supervisor must implement:

- Maximum restart attempts within a time window (e.g., max 5 restarts in 60s), OR
- Exponential backoff (e.g., 1s, 2s, 4s, 8s…), OR
- Both

Choose one minimal approach and document it. Prefer exponential backoff + max attempts.

##### Logging

Supervisor must log:

- start time of child
- child PID
- child exit code
- restart attempts count
- backoff time before restart

Logs must be written to a file, e.g.:

- `./logs/supervisor.log`

##### Signal Handling

Supervisor must handle:

- Ctrl+C (SIGINT) and SIGTERM to shut down cleanly
- On shutdown:
  - forward termination signal to the child
  - wait for child to exit (with a timeout, optional)
  - exit supervisor

Optional stretch:
- Support SIGHUP to restart child cleanly.



#### 3) ⚙️ Non-Functional Requirements

- **Reliability:** Child crashes are detected promptly and handled predictably
- **No restart storms:** Backoff and/or restart limits prevent runaway loops
- **Observability:** Clear logs for post-mortem debugging
- **Graceful shutdown:** Proper signal forwarding and cleanup
- **Portability:** Bash + coreutils only
- **Simplicity:** Keep policy understandable and documented
- **Correctness:** Avoid orphaned zombie processes

Optional stretch:
- Separate stdout/stderr logs for child processes
- Health checks (supervisor pings child or checks a heartbeat file)



#### 4) ▶️ How It Should Be Run

##### Setup

Create logs directory:

- `./logs/`

Make executable:

- `chmod +x supervisor.sh`

##### Run Example

Supervise a worker:

`./supervisor.sh -- ./worker.sh`

Supervise a command that crashes sometimes:

`./supervisor.sh -- bash -c 'echo running; sleep 1; exit 1'`

##### Verify Behavior

- Supervisor starts child
- Child exits with non-zero code
- Supervisor logs exit and restarts
- Backoff increases (if exponential backoff enabled)
- Ctrl+C stops supervisor and child cleanly



#### 5) 📦 Expected Outcomes

You should end up with:

- A reusable supervisor script with a clear restart policy
- Logs that show process lifecycle and restart behavior
- Correct signal handling (no orphaned child processes)
- A stable backoff strategy that prevents thrashing

You should be able to explain:
- how restart storms happen and how you prevented them
- what happens on SIGINT/SIGTERM
- what guarantees your supervisor provides



#### 6) 🧠 System Design Concepts Practiced

- Reliability patterns: restart policies, supervision
- Crash recovery and fault tolerance
- Backoff strategies and stability
- Signal handling and process lifecycle management
- Observability for operational systems
- Resource cleanup and avoiding zombie processes
- Separating control plane (supervisor) from data plane (worker)


---


### 8️⃣ Retry with Dead Letter Queue

#### 1) 🎯 Overview

Extend your job queue system (Projects 3–5) to handle failures robustly using retries and a Dead Letter Queue (DLQ).

In real systems, jobs fail for transient reasons (network hiccups, timeouts) and should be retried. Some failures are persistent (bad payload) and should be isolated so they don’t poison the entire system.

You will implement:

- a retry policy (max attempts, backoff)
- tracking of attempt counts
- a DLQ where permanently failing jobs are quarantined
- clear observability so you can reason about job outcomes

This turns your simple queue into a reliability-aware processing system.


#### 2) ✅ Functional Requirements

##### Retry Policy

When a job fails (non-zero exit code), the system must:

- Retry it up to a configurable max attempts (e.g., 3)
- Record attempt count per job
- Apply a retry strategy:
  - fixed delay (simplest), OR
  - exponential backoff (recommended)

Choose one default and document it. Optionally support both via flags/config.

##### Dead Letter Queue (DLQ)

If a job exceeds max retry attempts, it must be moved to a DLQ directory:

- `./dead/` (or `./dlq/`)

The DLQ item must include enough information to diagnose the failure:
- original job payload
- failure reason / last exit code
- timestamps
- attempt count
- last stderr/stdout (recommended)

##### Job State Directories

Your lifecycle directories should now include:

- `queue/`
- `processing/`
- `done/`
- `failed/` (optional: used for “failed but retryable” or just for last failure artifact)
- `dead/` (DLQ)
- `logs/`

You must define and document exactly what each directory means.

##### Attempt Tracking

Attempt count must be stored durably, using one of:

- job filename convention (e.g., job-001.attempt3)
- metadata sidecar file (e.g., job-001.meta)
- embedded metadata in payload
- structured directory layout

Pick one and document it.

##### Requeue Behavior

On retry, the system must:

- move job from `processing/` back to `queue/` (or a `retry/` staging area)
- enforce backoff delay before it is eligible to be re-processed

You must prevent immediate hot-loop retries.

Optional stretch:
- Use a scheduled retry directory with timestamps (e.g., `retry/2026-.../job`)

##### Logging and Audit

For each job, record:

- attempt number
- start time / end time
- exit code
- worker ID (if multi-worker is used)
- next retry time (if retrying)
- final outcome (done/dead)

Store this as:
- a per-job result file, and/or
- a central append-only audit log


#### 3) ⚙️ Non-Functional Requirements

- **No job loss:** Jobs must not disappear on failure
- **No infinite retries:** Hard cap on attempts
- **Backoff:** Avoid retry storms and tight loops
- **Durability:** Attempt tracking survives restarts
- **Concurrency safety:** Works correctly with multiple workers
- **Observability:** Easy to answer “why is this job in DLQ?”
- **Operational friendliness:** Clear structure for manual inspection and reprocessing
- **Minimal dependencies:** Bash + coreutils only

Optional stretch:
- Provide a command to re-enqueue a DLQ job after fixing it
- Provide a command to inspect job history by ID


#### 4) ▶️ How It Should Be Run

##### Setup

Ensure directories exist:

- `queue/`
- `processing/`
- `done/`
- `dead/`
- `logs/`

(Plus any others you choose such as `failed/`, `retry/`.)

##### Start Workers

Use your worker(s) from Project 4/5:

`./worker.sh &`  
`./worker.sh &`

##### Enqueue Jobs

Add:
- One job that succeeds
- One job that fails once then succeeds (simulate transient failure)
- One job that always fails (simulate permanent failure)

Example transient job idea:
- First run writes a marker file and exits 1
- Second run sees marker file and exits 0

##### Verify Behavior

- Transient failure job retries and eventually lands in `done/`
- Permanent failure job ends in `dead/` after max attempts
- Logs show attempt counts and backoff delays
- Queue does not get stuck retrying the same failing job forever


#### 5) 📦 Expected Outcomes

By the end, you should have:

- A queue system with resilient retry handling
- A DLQ quarantine that prevents poisoned jobs from blocking throughput
- Durable attempt tracking and clear audit logs
- A documented retry policy and DLQ policy
- Confidence in how your system behaves under failure

You should be able to answer:
- How many times was job X retried?
- Why did job Y go to DLQ?
- What is the system doing when many jobs fail simultaneously?


#### 6) 🧠 System Design Concepts Practiced

- Reliability patterns: retries, backoff, DLQ
- Transient vs permanent failure handling
- Poison message isolation
- Durable metadata tracking (attempt counts)
- Operational debugging and audit trails
- Failure-mode thinking: retry storms, hot loops, starvation
- Designing for safe manual intervention (requeue from DLQ)


---


### 9️⃣ Idempotent Deployment Script

#### 1) 🎯 Overview

Write an idempotent “deployment / provisioning” script in Bash that configures a machine (or a local sandbox environment) into a desired state. The key requirement is:

- You can run the script repeatedly and it will be safe and predictable.

This project is about building the habits used in real infrastructure automation:

- declarative thinking (“ensure X is true”) rather than imperative (“do X once”)
- detecting current state before changing it
- safe updates and rollbacks
- structured logging and clear failure behavior

You can target either:
- your local machine (carefully), OR
- a project-local sandbox directory (recommended), OR
- a container/VM (optional stretch)

The goal is the systems design thinking, not OS-specific package management.


#### 2) ✅ Functional Requirements

##### Desired State Specification

Your script must enforce a documented desired state, such as:

- Ensure specific directories exist with correct permissions
- Ensure config files exist with required content
- Ensure environment variables are set (via a `.env` or config file)
- Ensure a “service” script is installed and runnable
- Ensure a symlink points to the correct target
- Ensure a cron entry or scheduled job file exists (optional)

You must explicitly define your target state in a README section.

##### Idempotent Operations

For each resource type, your script must:

- Check current state first
- Only change state if it differs from desired state
- Report whether each step was:
  - “already correct” (no-op)
  - “changed” (made an update)
  - “failed” (with reason)

Resources to include (at least 5 of these):

- Create directories
- Create/update files (write config safely)
- Set file permissions
- Create symlinks
- Install “binary” script into `./bin/` (sandbox)
- Create a user-level configuration entry (sandbox version preferred)

##### Safe File Updates

When updating a file, you must use a safe strategy:

- write new content to a temp file
- validate it (optional)
- atomically move it into place

If a file already matches desired content, do nothing.

##### Dry Run Mode

Support a dry-run flag:

`./deploy.sh --dry-run`

Dry-run must:
- print what would change
- not actually apply changes

##### Rollback / Backup (Minimal)

For at least one critical file update, implement a basic rollback strategy:

- backup old file before overwrite
- restore on failure

Document what is and isn’t rollback-protected.


#### 3) ⚙️ Non-Functional Requirements

- **Idempotency:** Multiple runs lead to the same final state without side effects
- **Safety:** Avoid destructive operations; prefer sandbox paths
- **Atomicity:** Avoid partial writes (use temp + move)
- **Observability:** Clear step-by-step output and/or logs
- **Fail-fast:** If a critical step fails, stop with clear error
- **Portability:** Prefer POSIX tools; avoid OS-specific package managers unless you choose to target one OS explicitly
- **Testability:** Provide a way to reset the sandbox to test re-runs
- **Minimal dependencies:** Bash + coreutils only

Optional stretch:
- Structured logging (log levels)
- Summary report at end (# changed, # noop, # failed)
- “Plan” output similar to Terraform (what will change)


#### 4) ▶️ How It Should Be Run

##### Recommended Sandbox Layout

Use a project-local root so you don’t modify your system:

- `./sandbox/`
- `./sandbox/etc/`
- `./sandbox/bin/`
- `./sandbox/var/`

Script enforces desired state within `./sandbox`.

##### Example Runs

First run (applies changes):

`./deploy.sh`

Second run (should be mostly no-ops):

`./deploy.sh`

Dry run:

`./deploy.sh --dry-run`

Reset sandbox (you provide helper):

`./reset_sandbox.sh` (optional but recommended)

##### Verification

- Running deploy twice produces the same final file tree
- Second run reports mostly “already correct”
- No corrupted or partially written files exist


#### 5) 📦 Expected Outcomes

You should end up with:

- A deployment/provisioning script that is safe to run repeatedly
- A clear definition of “desired state” in documentation
- Evidence of idempotency via repeated runs
- A dry-run mode you can trust
- Safe update patterns (temp + move, backups where appropriate)
- A consistent reporting format (noop/changed/failed)

This project should feel like “mini configuration management” in Bash.


#### 6) 🧠 System Design Concepts Practiced

- Idempotency as a systems property
- Declarative vs imperative automation
- State detection and drift correction
- Safe writes and atomic updates
- Failure handling and rollback basics
- Observability of operations (what changed and why)
- Repeatability and reproducibility


---



## Level 4 - Simulated Distributed Systems (Local Only)
---

### 🔟 Leader Election (File-Based)

#### 1) 🎯 Overview

Simulate leader election among multiple “node” processes running on the same machine using filesystem primitives (locks + heartbeats). Exactly one node should act as the leader at any given time. If the leader dies, the remaining nodes should elect a new leader automatically.

This project is a local, simplified analogue of distributed coordination patterns (e.g., ZooKeeper/etcd leases), but implemented purely with shell processes and the filesystem.


#### 2) ✅ Functional Requirements

##### Nodes

Implement a node script:

`./node.sh`

You must be able to run multiple nodes simultaneously:

`./node.sh &`  
`./node.sh &`  
`./node.sh &`

Each node must have a stable identity, such as:
- PID
- a generated node ID (recommended), or
- a CLI-provided ID: `./node.sh --id node-1`

##### Leader Lock

Leader election must be based on a single shared “leadership lock” resource, using one of:

- `flock` on a lock file
- atomic lock directory creation: `mkdir leader.lock`
- atomic link creation
- another robust atomic mechanism (document your choice)

The system must ensure:
- at most one leader at a time (“no split brain” locally)
- leader identity is discoverable by followers

##### Heartbeat / Lease

Leader must periodically write a heartbeat that followers can observe, such as:

- update timestamp in `./state/leader_heartbeat`
- or touch a heartbeat file

Followers must detect leader failure by:
- checking heartbeat age exceeds a timeout (lease expiration), e.g. 5 seconds

When leader is considered dead:
- followers compete to acquire leadership lock

##### Leader Duties

When a node is leader, it must perform visible “leader work”, e.g.:

- write “I am leader” messages to `./logs/leader.log`
- increment a counter in `./state/leader_counter`
- emit periodic “LEADER” logs

Followers should emit “FOLLOWER” logs and display current leader identity.

##### Observability

System must expose:

- current leader ID (in a file, e.g. `./state/leader_id`)
- heartbeat timestamp (e.g. `./state/leader_heartbeat`)
- logs showing leadership transitions

##### Controlled Failure Simulation

Provide a way to simulate leader death:

- kill leader PID, or
- have node support `--crash-after N` seconds (optional stretch)

Document how to test failover.


#### 3) ⚙️ Non-Functional Requirements

- **Mutual exclusion:** Exactly one leader at a time (on a single machine)
- **Failover:** Leader failure detected and replaced within a bounded time (e.g., < 2 * heartbeat interval + lease)
- **Stability:** Avoid constant leader flapping (tune heartbeat/lease values; optional backoff on contention)
- **Low CPU usage:** Avoid tight spin loops; use sleep/backoff
- **Durability:** State files should not be corrupted; updates should be safe
- **Observability:** Logs clearly show elections and transitions
- **Minimal dependencies:** Bash + coreutils only

Optional stretch:
- Prevent “thundering herd” on leader death (randomized backoff)
- Handle stale lock files robustly (if using lock directory pattern)
- Add a “term number” that increments on each leadership change


#### 4) ▶️ How It Should Be Run

##### Setup

Create directories:

- `./state/`
- `./logs/`

Make executable:

- `chmod +x node.sh`

##### Run Nodes

Start 3 nodes:

`./node.sh --id node-1 &`  
`./node.sh --id node-2 &`  
`./node.sh --id node-3 &`

Observe:

- exactly one becomes leader
- others become followers

##### Simulate Leader Failure

Find leader PID and kill it:

`kill <leader_pid>`

Expected:
- within a short time, a follower becomes leader
- logs show leadership transition
- `./state/leader_id` updates

Stop all nodes:

- `kill` their PIDs or stop terminal session


#### 5) 📦 Expected Outcomes

You should end up with:

- A working leader election simulator with:
  - single-leader guarantee
  - heartbeat-based failure detection
  - automatic failover
- Clear observability:
  - leader ID file
  - heartbeat file
  - logs of transitions
- Documentation explaining:
  - how the lock is acquired atomically
  - how lease/heartbeat works
  - how to tune heartbeat interval and lease timeout
  - how to simulate failure and verify failover


#### 6) 🧠 System Design Concepts Practiced

- Leader election and mutual exclusion
- Leases and heartbeats (failure detection)
- Split-brain prevention (in a constrained environment)
- Coordination under contention
- Thundering herd and backoff strategies
- Control-plane responsibilities vs follower behavior
- Operational verification of distributed-ish behavior


---


### 1️⃣1️⃣ Log Replication Simulator

#### 1) 🎯 Overview

Build a simple log replication simulator in Bash that models a primary (leader) writing an append-only log and one or more replicas (followers) tailing and applying that log with configurable lag.

This is a local simulation of replication patterns used in databases and distributed systems:

- primary generates an ordered stream of events
- replicas consume the stream
- replicas may lag behind (eventual consistency)
- state is derived by replaying the log

You will focus on correctness and observability rather than performance.


#### 2) ✅ Functional Requirements

##### Components

Implement at least two roles:

- Primary: `./primary.sh`
- Replica: `./replica.sh --id r1`

Optional stretch:
- Multiple replicas: `./replica.sh --id r2`, etc.

##### Append-Only Log

Primary must write to an append-only log file, e.g.:

- `./state/primary.log`

Each log entry must include:
- monotonically increasing sequence number (required)
- timestamp
- event payload (simple text is fine)

Example conceptually:
- `seq=42 ts=... payload=SET x 10`

Primary must never rewrite existing log lines (append-only).

##### Primary Event Generation

Primary must generate events continuously or on demand:

- Continuous mode (recommended): `./primary.sh --rate 2` (2 events/sec)
- Optional one-shot: `./primary.sh --once`

Events can be simple operations like:
- increment a counter
- set a key/value pair
- append a random string

Choose a simple event schema and document it.

##### Replica Consumption and Apply

Replica must:
- track the last applied sequence number (persisted)
- read new log entries from the primary log
- apply them to replica state (derived state file)

Replica state could be:
- `./state/replica-r1.state`
- derived from replaying the log entries

Replica must expose:
- its current applied sequence number (offset)
- its lag (primary_seq - replica_seq)

##### Simulated Lag

Replica must support configurable lag, such as:

- `./replica.sh --id r1 --delay-ms 300`
or
- `--apply-rate 1` (1 event/sec)

This lets you demonstrate eventual consistency and replication delay.

##### Observability and Reporting

Provide a status command or script:

- `./status.sh`

It should show:
- current primary sequence number
- each replica’s applied sequence number
- lag for each replica

Optional stretch:
- print “replica caught up” events when lag reaches 0


#### 3) ⚙️ Non-Functional Requirements

- **Ordering correctness:** Replica must apply events in sequence order
- **Durability:** Replica offset must persist across restarts (no reapplying from scratch unless you choose that mode)
- **Append-only integrity:** Primary log must not be rewritten
- **Restartability:** You can stop and restart primary/replica without corrupting state
- **Bounded resource use:** Replica should not load entire log into memory; process incrementally
- **Observability:** Clear logs and a readable status view
- **Minimal dependencies:** Bash + coreutils only

Optional stretch:
- Handle malformed log lines gracefully (skip + report)
- Add basic checksum per line to detect corruption


#### 4) ▶️ How It Should Be Run

##### Setup

Create directories:

- `./state/`
- `./logs/` (optional)

Make scripts executable:

- `chmod +x primary.sh replica.sh status.sh`

##### Run Primary

Start primary generating events:

`./primary.sh --rate 5`

##### Run Replica(s)

Start a replica with artificial delay:

`./replica.sh --id r1 --delay-ms 200`

Optional: start another replica with different delay:

`./replica.sh --id r2 --delay-ms 1000`

##### Check Status

In another terminal:

`./status.sh`

Expected:
- primary seq increases steadily
- replicas follow behind depending on delay
- lag values reflect delay and throughput

##### Failure / Restart Tests

- Stop replica, let primary advance, restart replica:
  - replica should catch up from its last persisted offset
- Stop primary, restart primary:
  - ensure log remains append-only and sequence numbers remain monotonic


#### 5) 📦 Expected Outcomes

You should end up with:

- A working replication simulator with:
  - append-only primary log
  - replicas that tail and apply events
  - persistent offsets
  - configurable replication lag
- A status view showing lag and offsets
- Documentation explaining:
  - event format
  - how offsets are stored
  - how replicas apply events
  - what lag means and how it’s simulated

You should be able to demonstrate:
- eventual consistency (replica behind primary)
- catch-up after downtime
- ordered replay as a mechanism for building state


#### 6) 🧠 System Design Concepts Practiced

- Append-only logs as the source of truth
- Replication and eventual consistency
- Offsets / checkpoints and replay
- Derived state from log replay
- Lag measurement and operational visibility
- Failure recovery via persisted checkpoints
- Throughput vs latency tradeoffs (apply rate vs lag)


---


### 1️⃣2️⃣ Circuit Breaker

#### 1) 🎯 Overview

Build a circuit breaker wrapper in Bash that protects a system from repeatedly calling a failing dependency (e.g., an HTTP endpoint, a flaky command, a slow script). The circuit breaker should “open” after repeated failures, temporarily block further attempts, then “half-open” to test recovery.

This project teaches a key resilience pattern used in microservices and distributed systems:

- failure isolation
- fast-fail behavior under repeated errors
- recovery probing
- preventing cascading failures

You will implement a reusable wrapper script that can be placed in front of any command.


#### 2) ✅ Functional Requirements

##### Wrapper Interface

Provide a script that wraps an arbitrary command:

`./circuit_breaker.sh --name payments --fail-threshold 5 --cooldown 30 -- ./call_dependency.sh arg1`

Meaning:
- identify breaker instance by name (so state is per-dependency)
- open circuit after 5 failures
- when open, block calls for 30 seconds
- then allow a probe (half-open)

##### States

Implement the three classic states:

- CLOSED: calls allowed; failures counted
- OPEN: calls blocked; cooldown timer running
- HALF-OPEN: allow a limited number of “probe” calls to test if dependency recovered

At minimum:
- CLOSED and OPEN are required
- HALF-OPEN is strongly recommended and should be implemented if possible

##### Failure Counting

In CLOSED:
- if wrapped command exits non-zero, increment failure counter
- if wrapped command succeeds, reset failure counter (or decrease; choose and document)

When failure counter reaches threshold:
- transition to OPEN
- record “opened_at” timestamp

##### Cooldown Handling

In OPEN:
- reject calls immediately (fast fail) until cooldown expires
- return a distinct exit code for “circuit open”
- optionally print a clear message to stderr

After cooldown expiry:
- transition to HALF-OPEN (or CLOSED if you simplify, but document behavior)

##### Probe Behavior (HALF-OPEN)

In HALF-OPEN:
- allow a limited number of probe calls (e.g., 1)
- if probe succeeds:
  - transition to CLOSED
  - reset failure count
- if probe fails:
  - transition back to OPEN
  - restart cooldown

##### State Persistence

State must be persisted to disk so behavior survives restarts, using a per-breaker state file such as:

- `./data/cb_payments.state`

State must include (at minimum):
- current state (CLOSED/OPEN/HALF-OPEN)
- failure count
- last failure time (optional but useful)
- opened_at time (for cooldown)
- last probe time / probe count (if using HALF-OPEN)

##### Concurrency Safety

If multiple processes use the same breaker name concurrently:
- state updates must be coordinated safely (locking)

Use one of:
- `flock`
- atomic write + lock directory
- another documented approach

##### Exit Codes

Define clear exit codes, for example:
- 0: wrapped command ran and succeeded
- 1: wrapped command ran and failed
- 10: circuit is OPEN (call blocked)
- 2: usage/config error

Document your scheme.


#### 3) ⚙️ Non-Functional Requirements

- **Correctness:** State transitions must follow defined rules
- **Fast-fail:** OPEN state must return quickly without running command
- **Durability:** State file must not corrupt on crash/interruption
- **Atomicity:** State writes must be atomic (temp + move)
- **Concurrency safety:** No races that allow too many calls through in HALF-OPEN/OPEN
- **Observability:** Log transitions and decisions (optional file log recommended)
- **Configurability:** Name, threshold, cooldown, probe settings configurable
- **Minimal dependencies:** Bash + coreutils only

Optional stretch:
- Track rolling failure rate (more advanced)
- Add metrics output (counts of opens, blocks, probes)


#### 4) ▶️ How It Should Be Run

##### Setup

Create:

- `./data/`
- `./logs/` (optional)

Make executable:

- `chmod +x circuit_breaker.sh`

##### Test with a Flaky Command

Create a dependency that fails sometimes (or always):

- `./flaky.sh` exits non-zero randomly, or fails N times then succeeds

Run:

`./circuit_breaker.sh --name flaky --fail-threshold 3 --cooldown 10 -- ./flaky.sh`

Expected behavior:
- first failures increment counter
- at threshold, circuit opens
- subsequent calls return immediately with “circuit open” exit code
- after cooldown, a probe is allowed
- success closes breaker; failure reopens breaker

##### Concurrency Test (Optional)

Run multiple calls quickly in parallel:

- start several background invocations using the same breaker name
- verify state remains consistent and not too many probes happen



#### 5) 📦 Expected Outcomes

You should end up with:

- A reusable circuit breaker wrapper script
- A clearly documented state machine with transitions
- A persisted state file per breaker name
- Correct OPEN behavior (fast fail) and recovery behavior (cooldown + probe)
- Test scripts that demonstrate:
  - repeated failure triggers open
  - cooldown blocks calls
  - half-open probe determines recovery

You should be able to explain:
- how circuit breakers prevent cascading failure
- what guarantees your implementation provides under concurrency
- how cooldown and probe settings affect stability



#### 6) 🧠 System Design Concepts Practiced

- Resilience patterns: circuit breaker
- State machines and transition rules
- Failure isolation and fast-fail design
- Concurrency-safe shared state (locking)
- Recovery probing (half-open)
- Avoiding cascading failures and retry storms
- Operational tuning (thresholds, cooldowns, probes)


---


## Stretch Project Ideas (Hard Mode)
---

### 1️⃣3️⃣ Mini Cron

#### 1) 🎯 Overview

Build a mini “cron-like” scheduler in Bash that can run commands on a schedule. It should read a schedule configuration, determine when jobs are due, execute them, and record outcomes.

This project teaches scheduling fundamentals and operational concerns:

- time-based triggering
- job definitions and configuration parsing
- preventing overlapping runs
- logging and failure handling
- persistence of last-run timestamps

You are not trying to fully replicate cron’s full syntax; instead you will implement a minimal but robust subset.


#### 2) ✅ Functional Requirements

##### Scheduler Interface

Provide a scheduler script:

`./mini_cron.sh --config ./config/jobs.conf`

It should run continuously until stopped.

Optional:
- `--once` mode to run a single scheduling cycle and exit (useful for testing)

##### Job Configuration Format

Implement a simple job config file format. Choose one and document it clearly:

Option A (key=value lines per job):
- `name=backup interval_sec=60 command="./backup.sh"`

Option B (CSV):
- `backup,60,./backup.sh`

Option C (simple cron subset like “every N minutes”):
- `backup */1m ./backup.sh`

Minimum fields per job:
- job name (unique)
- schedule definition (at least interval-based)
- command to run

##### Supported Scheduling Features (Minimum)

Implement at least:

- Run every N seconds (interval scheduling)

Optional stretch:
- Every N minutes
- Fixed times of day (e.g., daily at 03:00)
- Simple day-of-week filtering

##### Due Calculation + State Tracking

Scheduler must determine when each job is due based on:

- current time
- last-run time of that job

Last-run state must be persisted in a durable state file, e.g.:

- `./state/mini_cron.state`

State must survive restarts.

##### Execution Semantics

When a job is due:

- execute its command
- capture exit code
- record start/end times
- log output (optional but recommended)

##### Overlap / Concurrency Control

Prevent overlapping runs of the same job. If a job is still running when it becomes due again:

- do not start a second instance of that job
- record a “skipped due to overlap” event in logs

Implement overlap control using one of:
- lock file per job
- `flock`
- PID file

Document your mechanism.

##### Logging

Write an append-only scheduler log with:
- timestamp
- job name
- event type (RUN/OK/FAIL/SKIP)
- duration
- exit code

Example log path:
- `./logs/mini_cron.log`



#### 3) ⚙️ Non-Functional Requirements

- **Correctness:** Jobs trigger at approximately the right time (within a small tolerance)
- **Durability:** Last-run state survives restarts and isn’t corrupted
- **No overlaps:** Same job should not run concurrently
- **Observability:** Clear logs and per-job outcomes
- **Graceful shutdown:** Ctrl+C stops scheduler cleanly and doesn’t corrupt state
- **Resource efficiency:** Avoid high CPU usage (sleep between cycles)
- **Minimal dependencies:** Bash + coreutils only
- **Robust parsing:** Bad config lines should be rejected with clear errors

Optional stretch:
- Allow a global max concurrency limit across all jobs
- Add jitter to reduce “thundering herd” if many jobs due at once



#### 4) ▶️ How It Should Be Run

##### Setup

Create directories:

- `./config/`
- `./state/`
- `./logs/`

Make executable:

- `chmod +x mini_cron.sh`

Create job config:

- `./config/jobs.conf`

Example conceptual config (document your chosen format):
- backup every 60 seconds
- cleanup every 300 seconds

##### Run Scheduler

Start:

`./mini_cron.sh --config ./config/jobs.conf`

Stop:

- Ctrl+C

##### Verify Behavior

- jobs run at expected intervals
- logs show RUN/OK/FAIL events
- last-run state file updates
- overlapping runs are prevented (test with a job that sleeps longer than its interval)



#### 5) 📦 Expected Outcomes

You should end up with:

- A working minimal scheduler that reads config and runs jobs on schedule
- Persisted last-run state so it can resume correctly after restart
- Overlap prevention per job
- Clear execution logs and outcomes
- Documentation describing:
  - the schedule format you support
  - how due calculations work
  - overlap policy and locking method
  - how to test and troubleshoot

You should be able to demonstrate:
- restart behavior (scheduler stops and resumes without double-running jobs immediately)
- handling long-running jobs without overlapping
- basic operational inspection via logs/state



#### 6) 🧠 System Design Concepts Practiced

- Scheduling and time-based triggering
- State persistence (last-run tracking)
- Concurrency control (per-job locks)
- Failure handling and logging
- Config parsing and validation
- Operational reliability (restart, observability)
- Preventing overload and overlap



---


### 1️⃣4️⃣ Mini systemd (Service Manager)

#### 1) 🎯 Overview

Build a minimal “service manager” in Bash inspired by systemd/supervisord. It should be able to manage multiple long-running services defined in a config file, including:

- start / stop / restart
- status reporting
- automatic restart on crash (optional but recommended)
- logging per service

This project is a step up from the Supervisor (Project 7). Instead of supervising one command, you’ll manage a set of services with a control interface and persistent state.

You are not trying to replicate systemd fully. You’re building a small, understandable service manager with core control-plane concepts.



#### 2) ✅ Functional Requirements

##### Service Definitions (Config)

Services must be defined in a config file, e.g.:

- `./config/services.conf`

Each service definition must include at minimum:
- service name (unique)
- command to run
- working directory (optional)
- restart policy (optional)
- environment variables (optional)

You must choose a simple config format and document it. Examples:
- INI-like blocks
- key=value per service line
- one file per service in `./services/`

##### Control Interface

Provide a control script:

`./svc.sh <command> <service>`

Supported commands:
- `start <service>`
- `stop <service>`
- `restart <service>`
- `status <service>`
- `status --all`
- `logs <service>` (optional, but useful)

Optional stretch:
- `enable/disable` (persist whether service should run on manager start)

##### Start Semantics

When starting a service:
- launch it in the background
- record its PID in a PID file, e.g. `./run/<service>.pid`
- record start timestamp
- redirect stdout/stderr to log files, e.g. `./logs/<service>.log`

Must prevent duplicate starts:
- If service is already running, `start` should be a no-op with a clear message.

##### Stop Semantics

When stopping a service:
- send SIGTERM to PID
- wait for exit (with timeout)
- if not stopped, optionally send SIGKILL (document policy)
- remove PID file when fully stopped

##### Status Semantics

`status <service>` must report:
- running or not running
- PID (if running)
- uptime (optional but recommended)
- last exit code (if tracked)
- restart count (if restart policy enabled)

`status --all` must list all services with their states.

##### Manager Loop (Optional but Recommended)

Provide a “manager daemon”:

`./mini_systemd.sh --config ./config/services.conf`

It should:
- monitor running services
- restart crashed services according to restart policy
- maintain restart counts and backoff
- keep state durable enough to provide status

If you don’t build a daemon, you must still support start/stop/status, but you lose “auto restart” unless you implement it in another way.

##### Restart Policies (If Implemented)

Support at least:
- `no` (never restart)
- `on-failure` (restart on non-zero exit)
- `always` (restart regardless)

Must implement:
- max restart attempts per time window OR exponential backoff (recommended)

##### Logging

Per-service logs:
- stdout/stderr redirected to `./logs/<service>.log`

Manager log (optional but recommended):
- events like start/stop/restart/crash: `./logs/manager.log`



#### 3) ⚙️ Non-Functional Requirements

- **Correctness:** Start/stop/status reflect real process state
- **Safety:** No orphan processes; PID files accurate and cleaned up
- **Observability:** Clear logs and status output
- **Resilience:** If auto-restart enabled, avoid restart storms (backoff/limits)
- **Concurrency safety:** Prevent races if user runs commands quickly (basic locking recommended)
- **Portability:** Bash + coreutils only
- **Operational clarity:** Simple directory layout (`run/`, `logs/`, `config/`)
- **Graceful shutdown:** Manager daemon stops cleanly and optionally stops/keeps services (document behavior)

Optional stretch:
- Support dependencies (service A must start before B) — keep simple if attempted
- Support “health check” command per service and restart if unhealthy
- Provide a `tail -f` style log command



#### 4) ▶️ How It Should Be Run

##### Setup

Create directories:

- `./config/`
- `./run/`
- `./logs/`

Make scripts executable:

- `chmod +x svc.sh mini_systemd.sh`

Create a few dummy services to manage, e.g.:
- a worker loop that prints a heartbeat
- a flaky service that exits randomly
- a long-running `sleep` wrapper

##### Example Usage (Control Script)

Start a service:

`./svc.sh start worker`

Check status:

`./svc.sh status worker`

Stop:

`./svc.sh stop worker`

Restart:

`./svc.sh restart worker`

View all:

`./svc.sh status --all`

##### Example Usage (Manager Daemon)

Start manager loop:

`./mini_systemd.sh --config ./config/services.conf`

In another terminal, start services using `svc.sh`, or have the manager auto-start enabled services (optional stretch).

##### Verify Behavior

- Services start and produce logs
- PID files reflect reality
- Stop cleans up processes and PID files
- Status reports accurate state
- If restart policy enabled, crashes lead to controlled restarts with backoff



#### 5) 📦 Expected Outcomes

You should end up with:

- A minimal multi-service manager that can start/stop/status multiple services
- A clear service definition format and directory layout
- PID-file based tracking and safe process control
- Per-service logs and (optionally) a manager event log
- If daemon monitoring implemented:
  - restart policies and backoff working
  - restart counts visible in status

You should be able to explain:
- why PID files can lie and how you validate them
- how you prevent double-start and zombie/orphan processes
- how restart storms happen and how you avoided them



#### 6) 🧠 System Design Concepts Practiced

- Control plane vs data plane (manager vs services)
- Process lifecycle management and supervision at scale
- State tracking via PID files + validation
- Restart policies and backoff stability
- Observability: logs, status, uptime, counters
- Operational UX: CLI interfaces for operators
- Managing multiple independent workloads safely




---


### 1️⃣5️⃣ Simple HTTP Server Using netcat (nc)

#### 1) 🎯 Overview

Build a minimal HTTP server using `nc` (netcat) and Bash that can accept TCP connections, parse basic HTTP requests, and return valid HTTP responses.

This project is about understanding foundational web/server concepts by building them from first principles:

- request/response over TCP
- HTTP framing (request line, headers, body)
- routing
- status codes
- concurrency model (single-threaded vs multi-process)
- basic observability (access logs)

You are not trying to build a production-grade web server. You are building a learning tool that behaves correctly for a small subset of HTTP.



#### 2) ✅ Functional Requirements

##### Server Startup

Provide a server script:

`./server.sh --host 127.0.0.1 --port 8080`

Defaults:
- host: 127.0.0.1
- port: 8080

##### Connection Handling

Server must:
- listen on the configured host/port
- accept incoming connections
- read one HTTP request per connection (minimum)
- respond and close the connection

Optional stretch:
- HTTP keep-alive for multiple requests per connection (advanced)

##### Request Parsing (Minimum)

Parse at least:
- HTTP method (GET is required; POST optional)
- request path (e.g. `/`, `/health`, `/echo`)
- HTTP version (e.g. HTTP/1.1)
- headers (at least Host; capture others if possible)

Handle malformed requests:
- respond with 400 Bad Request

##### Routing (Minimum)

Implement these routes:

- GET `/health`
  - returns 200 OK with a short body like `OK`

- GET `/`
  - returns 200 OK with a basic HTML or text page

- GET `/time`
  - returns current server time

- GET `/echo?msg=hello` (optional but recommended)
  - parses query string and returns the message

Unknown path:
- returns 404 Not Found

##### Responses

Responses must be valid HTTP and include:
- status line (e.g. `HTTP/1.1 200 OK`)
- required headers:
  - `Content-Length`
  - `Content-Type`
  - `Connection: close`
- response body

##### Logging

Write an access log entry per request to:

- `./logs/access.log`

Include:
- timestamp
- client address (if available)
- method
- path
- status code
- response size (optional)

##### Concurrency (Two Modes)

Implement at least one mode:

- Single-threaded: one request at a time

Optional stretch:
- Multi-process concurrency: spawn a handler per connection (or use a loop that forks)
- Document chosen model and tradeoffs



#### 3) ⚙️ Non-Functional Requirements

- **Correctness:** Must return syntactically valid HTTP responses for supported routes
- **Robustness:** Must handle malformed input without crashing
- **Observability:** Logs must be readable and consistent
- **Resource safety:** Avoid runaway processes; ensure server stops cleanly
- **Portability:** Bash + `nc` + coreutils only (document nc variant assumptions if needed)
- **Low complexity:** Keep the supported HTTP subset explicit and documented
- **Security awareness:** Bind to localhost by default; avoid executing untrusted input

Optional stretch:
- Basic request timeouts to avoid hanging on slow clients
- Basic rate limiting (tie-in with Project 6)



#### 4) ▶️ How It Should Be Run

##### Setup

Create logs directory:

- `./logs/`

Make executable:

- `chmod +x server.sh`

Ensure `nc` is installed and discoverable:

- `nc -h` should work

##### Run Server

Start server:

`./server.sh --port 8080`

##### Test Requests

Using curl:

- `curl -i http://127.0.0.1:8080/health`
- `curl -i http://127.0.0.1:8080/`
- `curl -i http://127.0.0.1:8080/time`

Test unknown route:

- `curl -i http://127.0.0.1:8080/does-not-exist`

Verify logs:

- inspect `./logs/access.log`

Stop server:

- Ctrl+C should stop cleanly



#### 5) 📦 Expected Outcomes

You should end up with:

- A working minimal HTTP server that:
  - listens on a port
  - parses simple requests
  - routes to handlers
  - returns correct HTTP responses
- Access logs that record requests and outcomes
- Documentation explaining:
  - supported routes
  - supported HTTP methods
  - limitations (no keep-alive, limited headers, etc.)
  - concurrency model chosen

You should be able to explain:
- how HTTP rides on TCP
- what makes a response “valid”
- how servers implement routing and status codes
- how concurrency impacts throughput and complexity


#### 6) 🧠 System Design Concepts Practiced

- Request/response protocol design over TCP
- Parsing and validation of external inputs
- Routing and handler abstraction
- Status codes and error handling semantics
- Observability (access logs)
- Concurrency models (single-thread vs multi-process)
- Security and safe defaults (localhost binding, no code injection)



---


### 1️⃣6️⃣ Metrics Collector Exposing /metrics

#### 1) 🎯 Overview

Build a simple metrics collector in Bash that tracks counters and timings for your “systems from shell” projects (e.g., queue workers, scheduler, HTTP server) and exposes them in a Prometheus-style text format at an HTTP endpoint: `/metrics`.

This project is about observability and system instrumentation:

- what to measure (counters, gauges, histograms-ish)
- how to update metrics safely from multiple processes
- how to expose metrics in a scrape-friendly format
- how to keep metrics durable and consistent

You’ll implement two parts:
1) a metrics library/interface for updating metrics
2) a tiny HTTP endpoint that serves the metrics snapshot


#### 2) ✅ Functional Requirements

##### Metrics Storage

Implement a metrics store backed by the filesystem, for example:

- `./metrics/` directory
- one file per metric (recommended) OR a single structured file

Metrics must support at least:

- Counter: monotonically increasing (e.g., `jobs_processed_total`)
- Gauge: can go up/down (e.g., `queue_depth`)
- Timer/latency: record durations (minimum: last duration; optional: count + sum)

You must document your chosen storage format and naming conventions.

##### Metrics Update Interface

Provide a CLI/script interface to update metrics, e.g.:

- `./metrics.sh inc jobs_processed_total`
- `./metrics.sh add jobs_bytes_total 512`
- `./metrics.sh set queue_depth 12`
- `./metrics.sh observe job_duration_ms 37` (optional)

This interface must be callable from other scripts (workers, scheduler, server).

##### Concurrency Safety

Updates must be safe when multiple processes update metrics simultaneously.

You must implement coordination using one of:
- `flock`
- per-metric lock files or lock directories
- atomic write patterns (temp + move)

Document your locking design (granularity and tradeoffs).

##### Metrics Endpoint

Expose an HTTP endpoint:

- GET `/metrics`

that returns metrics in Prometheus-style text exposition format, e.g.:

- `jobs_processed_total 123`
- `queue_depth 5`

You can implement the HTTP endpoint using:
- your nc-based server from Project 15, OR
- a minimal dedicated `nc` listener just for metrics

The endpoint must:
- return 200 OK
- include `Content-Type: text/plain; version=0.0.4` (or `text/plain`)
- include correct `Content-Length`
- return a consistent snapshot of metrics

##### Metric Snapshot Consistency

When serving `/metrics`:
- metrics output should represent a consistent view
- avoid partially-written metrics appearing mid-update

You must choose and document how you ensure consistency, e.g.:
- global read lock during snapshot
- atomic per-metric writes so reads are always safe
- snapshot file built then swapped atomically

##### Sample Instrumentation

Instrument at least one existing script (or a demo script) to update metrics, e.g.:
- worker increments `jobs_processed_total`
- worker increments `jobs_failed_total`
- scheduler increments `jobs_run_total`
- server increments `http_requests_total{path="/health"}` (labels optional stretch)

You don’t need full Prometheus label support, but you can simulate labels by encoding them in metric names if desired (document approach).


#### 3) ⚙️ Non-Functional Requirements

- **Correctness:** Counters/gauges update accurately under concurrency
- **Atomicity:** No corrupted or partially written metric values
- **Durability:** Metrics persist across restarts (unless you choose ephemeral and document it)
- **Observability:** Output format is scrape-friendly and documented
- **Efficiency:** Updates are lightweight; endpoint responds quickly
- **Portability:** Bash + coreutils + `nc` only
- **Security:** Bind to localhost by default; avoid exposing sensitive data

Optional stretch:
- Provide a “reset metrics” command for testing
- Add basic metric metadata lines (`# HELP`, `# TYPE`)
- Add a simple histogram-ish format (count/sum/buckets)


#### 4) ▶️ How It Should Be Run

##### Setup

Create directories:

- `./metrics/`
- `./logs/` (optional)

Make scripts executable:

- `chmod +x metrics.sh metrics_server.sh`

##### Run Metrics Server

Start server:

- `./metrics_server.sh --host 127.0.0.1 --port 9100`

##### Update Metrics (Manual Test)

Increment a counter:

- `./metrics.sh inc jobs_processed_total`

Set a gauge:

- `./metrics.sh set queue_depth 3`

##### Query Endpoint

Using curl:

- `curl -i http://127.0.0.1:9100/metrics`

Expected:
- HTTP 200 OK
- text/plain body containing the metrics lines

##### Concurrency Test

Run updates in parallel:

- start multiple background `inc` operations
- verify counter ends at expected value with no corruption


#### 5) 📦 Expected Outcomes

You should end up with:

- A simple, reusable metrics interface (`metrics.sh`)
- A running metrics endpoint serving `/metrics`
- A durable, concurrency-safe metrics store
- At least one other project instrumented to emit metrics
- Documentation explaining:
  - supported metric types
  - storage format
  - concurrency/locking strategy
  - endpoint behavior and output format

You should be able to explain:
- why observability is a first-class system concern
- how you ensure safe concurrent metric updates
- how scraping works conceptually


#### 6) 🧠 System Design Concepts Practiced

- Observability primitives: counters, gauges, timings
- Shared state under concurrency (safe increments)
- Snapshot consistency and atomic reads
- API design: small CLI interface for metrics updates
- Separation of concerns: instrumentation vs serving vs storage
- Operational thinking: “how do I know my system is healthy?”



---

### 1️⃣7️⃣ Shell-Based Event Bus Using Named Pipes (FIFOs)

#### 1) 🎯 Overview

Build a simple event bus in Bash using named pipes (FIFOs) to publish and subscribe to events between multiple processes.

This project simulates core messaging system ideas locally:

- publishers emit events
- subscribers receive events
- the bus provides a communication channel decoupling producers from consumers

You’ll explore tradeoffs around:

- fan-out (one message to many subscribers)
- delivery semantics (best-effort vs at-least-once)
- buffering and backpressure (slow subscribers)
- lifecycle management (subscribe/unsubscribe)
- observability

Because a FIFO is a low-level primitive (not a full message broker), your design will need to build structure around it.



#### 2) ✅ Functional Requirements

##### Bus Creation and Lifecycle

Provide a bus script to create and manage bus resources:

- `./bus.sh init`
- `./bus.sh teardown` (optional but useful)
- `./bus.sh status` (optional)

The bus must create required directories and named pipes under a predictable path, e.g.:

- `./bus/`
- `./bus/topics/`
- `./bus/subscribers/`
- `./logs/`

##### Topics

Support at least one topic:

- `events`

Optional stretch:
- multiple topics (e.g., `orders`, `metrics`, `alerts`)

Each topic must have a named pipe, e.g.:

- `./bus/topics/events.fifo`

##### Publishing

Provide a publisher interface:

- `./publish.sh --topic events --event "USER_SIGNED_UP user_id=123"`

Or:
- `./bus.sh publish events "..."`

Publishing must:
- write an event line to the topic
- include a timestamp (either added by publisher or required in payload)
- include an event type/name and payload

You must define and document the event format (simple line protocol is fine):
- `ts=<...> type=<...> key=value ...`

##### Subscribing

Provide a subscriber interface:

- `./subscribe.sh --topic events --id sub1`

Subscribers must:
- connect to the topic
- receive events continuously
- process events via a handler (can be inline or callback command)
- write subscriber output to a log file:
  - `./logs/sub1.log`

At minimum, subscriber handler can just print received events with subscriber ID.

Optional stretch:
- allow passing a handler command: `--handler ./handle_event.sh`

##### Fan-out Delivery (One-to-Many)

You must implement a design that allows multiple subscribers to receive events from the same topic.

Note:
- A single FIFO does not naturally broadcast to multiple readers reliably the way you want.
- Therefore, your “bus” must implement fan-out explicitly.

Acceptable approaches include:
- a central “router” process that reads from the topic FIFO and writes to per-subscriber FIFOs
- per-subscriber pipes with the router duplicating messages
- using `tee` in a controlled way (with per-subscriber sinks)

You must document the approach and how subscribers register/unregister.

##### Subscriber Registration

Subscribers must register themselves so the bus/router knows where to send events.

At minimum:
- a subscriber creates its own FIFO (e.g., `./bus/subscribers/sub1.fifo`)
- subscriber registers by writing its FIFO path to a registry file or directory entry

##### Backpressure / Slow Subscriber Behavior

You must define what happens if a subscriber is slow or disconnected. Choose and document one policy:

- Block the router (strict delivery; can stall entire bus)
- Drop events for that subscriber (best-effort fan-out)
- Buffer temporarily (bounded) and then drop (recommended if you attempt)

This can be implemented simply at first:
- best-effort with drop if write blocks too long (optional)
- or require subscribers to be fast

##### Basic Observability

Provide at least:
- bus/router log: `./logs/bus.log`
- count of events published
- count of events delivered per subscriber (optional stretch)



#### 3) ⚙️ Non-Functional Requirements

- **Correctness (chosen semantics):** Must match documented delivery behavior
- **Fan-out support:** Multiple subscribers receive the same events
- **Stability:** Router should not crash on subscriber disconnects
- **Resource cleanup:** FIFOs and registry entries cleaned up on unsubscribe/exit where possible
- **Low CPU usage:** Avoid busy loops; block on reads
- **Portability:** Bash + coreutils only; use `mkfifo`
- **Security:** Bind bus to local filesystem only; avoid executing arbitrary payloads

Optional stretch:
- Add topic permissions (who can publish/subscribe)
- Add message ordering guarantees per topic



#### 4) ▶️ How It Should Be Run

##### Setup

Make scripts executable:

- `chmod +x bus.sh publish.sh subscribe.sh`

Initialize bus:

- `./bus.sh init`

Start router (if your design uses a router process):

- `./bus.sh run-router events &`

Start two subscribers:

- `./subscribe.sh --topic events --id sub1 &`
- `./subscribe.sh --topic events --id sub2 &`

Publish events:

- `./publish.sh --topic events --event "type=PING msg=hello"`
- `./publish.sh --topic events --event "type=ORDER_CREATED order_id=42"`

Verify:
- both subscribers receive events (check their logs)
- router/bus logs show deliveries

Teardown (optional):

- `./bus.sh teardown`



#### 5) 📦 Expected Outcomes

You should end up with:

- A working local event bus with:
  - a publish interface
  - a subscribe interface
  - fan-out delivery via a router or equivalent mechanism
- A documented event format and topic structure
- Logs proving events are delivered to multiple subscribers
- Documented delivery/backpressure semantics

You should be able to demonstrate:
- adding/removing subscribers
- broadcasting an event to all subscribers
- what happens when a subscriber is slow or disconnected (based on your policy)



#### 6) 🧠 System Design Concepts Practiced

- Publish/subscribe architecture
- Messaging semantics (best-effort vs blocking delivery)
- Fan-out and routing
- Backpressure and slow consumer handling
- Registration/discovery of consumers
- Observability of message flow
- Building abstractions over low-level primitives (FIFOs)


---