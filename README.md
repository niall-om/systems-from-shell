# systems-from-shell
System design experiments using shell + OS primitives 
***(learning in public, from first principles)***

This repository documents my learning journey as I explore Operating System fundamentals, Bash shell scripting, and core systems designs concepts. I am very much a beginner in many of these areas. The goal here is not to present "best practices" or production-ready systems, but to learn by building small, sometimes awkward, often broken systems and observing how they behave. 

The repository is a collection of hands-on experiments exploring **operating system primitives, Bash shell scripting, and systems design concepts** using the Unix toolchain. The core idea is to use **Shell + OS primitives** (processes, pipes, FIFOs, file descriptors, signals, blocking semantics, etc.) as a low-level playground for understanding what higher-level systems and frameworks are doing under the hood.

---
## What this repo is (and isn't)
This repo **is**:
- a place to experiment
- a record of mistakes, dead ends, and "aha" moments
- a way to make abstract system concepts concrete
- an excuse to really understand how pipes, processes and file descriptors and other low-level "magic" work.

This repo **is not**:
- a collection of polished libraries
- an example of how to build production systems in bash
- authoritive guidance on system design 

If something looks clunky or over-engineered, that's usually intentional and part of the learning (or because I don't yet know what I don't know!)


## Goals

1.	Learn operating system fundamentals
    - Processes and lifecycle coordination
    - File descriptors and I/O
    - Pipes, FIFOs, blocking semantics
    - Signals, exit status, resource cleanup


2.	Get more comfortable with Bash scripting skills
    - Process orchestration
    - I/O redirection and wiring
    - Concurrency and synchronization
    - Error handling and lifecycle management

3.	Explore systems design ideas at a low level
    - Work queues and scheduling
    - Backpressure and flow control
    - Fault isolation and recovery
    - Separation of concerns (control plane vs data plane)
    - Logging, observability, and lifecycle management


## Philosophy

The guiding idea is simple: **Use the simplest tools possible, and look closely at how they fail.**

Working at the shell level forces me to be explicit about things like:
- who owns file descriptors
- when something blocks
- what happens when a process exits
- how cleanup actually works
- concurrency issues - what the OS does and does not guarantee

Shell is used not because it is the “right” tool for production systems, but because it makes system behavior visible.

Ideally this approach will surface the kinds of "oh, that's why this exists" moments that explain why modern systems rely on queues, caching, retries, and similar building blocks.


## Repository Structure

- `projects/` – Individual system design experiments and learning projects
- `_template/` – Starter template for new projects
- `scripts/` – Executable entry-point scripts for running and orchestrating systems
- `utils/` – Shared shell helper functions intended to be sourced by scripts
- `notes/` – Cross-project notes and learning references
- `docs/` – Diagrams and reference documentation


`projects/`


>Contains all concrete subsystem experiments and mini-projects. 
>Each subdirectory represents a **self-contained system design exercise**, typically exploring:
>- concurrency
>- orchestration
>- IPC (pipes, FIFOs, signals)
>- failure modes
>- lifecycle management
>
>Project Conventions:
>Every project should contain:
>- README.md - problem statement, goals, and high-level design
>- DECISIONS.md - design decisions, trade-offs, and dead ends
>- scripts/ - runnable experiments or demos
>- docs/ - diagrams or extended explanations (optional)
>Projects are expected to be *runnable, inspectable, and breakable*


`projects/_template/`

>A **starter template** for new projects.
>
>This directory is copied when beginning a new experiment and provides:
>- a standard folder layout
>- a project-level README.md
>- a project-level DECISIONS.md decision log
>- optional placeholders for scripts and docs
>
>**How to use:**
>1. Copy _template/ into projects
>2. Rename it to your new project name
>3. Fill in README.md and start hacking
>
>The template itself is **not an active project.**

`notes/`

>Cross-cutting learning notes that span multiple projects.
>
>Used for:
>- Bash semantics
>- OS concepts
>- IPC behaviour
>- system design reflfections
>- patterns discovered across experiments
>
>These notes are **conceptual**, not project-specific


## Project Ideas

For future expansions and experimental ideas, see  
👉 [Project Ideas](project_ideas.md)


## Project Index

This section lists concrete system design experiments contained in the `projects/` directory. Projects will evolve over time as understanding deepens. Earlier versions are kept intentionally to document learning process.


