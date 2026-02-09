---

## `_template/DECISIONS.md`

This is one of the most valuable files — treat it like a lab notebook.

A brief guide to using...

A decision log is not:
- a diary
- a progress log
- a dump of thoughts

A decision log is:
- a record of intentional choices you made, when you could have done something else.
- if there was no real alternative, it usually doesn't belong here
- Think of it as "Why does the system look like this instead of some other way?"

Conventions:
- Each section is:
    - date-based and chronlogical
    - describes one decision or cluster of related decisions
    - you should be able to clearly state the decision in one line "outcomes"
    - if you can't summarise the decision in one sentence, it is probably multiple decisions

- Context:
    - this the why the decision existed
    - answers questions like - What problem was I trying to solve? What constraint mattered? What had I just learned that influenced this? 

- Alternatives considered:
    - This is the critical thinking part
    - List real alternatives you thought about
    - Even if you rejected something quickly, writing it down matters   

- Why this choice?:
    - This is the reasoning - not justification
    - Good answers
        - simpler lifecyle
        - fewer deadlocks
        - aligns with Unix pipeline semantics
        - easier to reason about failure
    - Bad answers
        - felt cleaner
        - seemed right
    - Force yourself to be explicit


When to use it/when not to use it:
- Do not log (these should all go in NOTES.md and commit messages)
    - bug fixes
    - typos
    - minor refactors
    - today I learned X

- Log only structural or conceptual choices
    - Think of decision log as Architecture commmit messages, but human-readable and timeless
    - Code tells you what happened, Decision logs tell you why

- Rules of thumb on usage
    - if future-you might ask why did I do this -> log it
    - if you debated for more than ~5 minutes -> log it
    - if it changes architecture, responsibility, or ownership -> log it
    - expect 3-10 entries per project, not hundreds

---

# Design Decisions

## YYYY-MM-DD — Initial Design

**Decision**
- …

**Context**
- …

**Alternatives Considered**
- …

**Why This Choice**
- …


## YYYY-MM-DD — Change X

**What Changed**
- …

**Why**
- …

**Trade-offs Introduced**
- …