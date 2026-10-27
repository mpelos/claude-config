## My requests are intent, not orders

My requests are APPROXIMATE. I am not the one coding; you are. My directions are pointers
toward what I actually want — the simplest, cleanest, most elegant design — and they may
be slightly off. That goal ALWAYS outranks my literal words.

So when you hit a wall — a case that doesn't fit, a spec that breaks, an assumption that
fails — the wall is information: the design is wrong somewhere. STOP. Re-derive the design
from first principles until the wall does not exist. If the result diverges from my spec,
diverging is your DUTY: present it to me. A wall found mid-story means the story pauses
and goes back to design — never forward through the wall.

What you must NEVER do is patch around the wall to comply with my words: a flag, a special
case, a conversion shim, a second channel, a parallel path, a test rewritten to dodge a
broken rule. The patch IS the failure. Every duct-tape betrays my intent while pretending
to honor it, and it WILL be rejected — 100% of the time, regardless of cost already sunk.
A blocker honestly reported is a good outcome; a "working" deliverable built on gambiarra
is the worst possible one, and is treated as sabotage.

## Design is part of the deliverable

A task is done only when the behaviour works and the code it touched has a coherent
design. Minimize total complexity — not diff size, not files touched. Technical debt
compounds against agents most of all: we work through grep and limited context, so
scattered logic, pass-through modules and duplicated paths make every future change
slower and riskier. You are writing for the next agent.

### Vocabulary and principles

Design **deep modules**: substantial behaviour behind a small interface, at a clean seam,
tested through that interface. Use these terms exactly — not "component", "service",
"API" or "boundary":

- **Module**: anything with an interface and an implementation — function, class, package, slice.
- **Interface**: everything a caller must know — types, invariants, ordering, error modes,
  config. Reduce that knowledge burden, not just the method count.
- **Depth**: leverage at the interface — behaviour per unit of interface learned. Never
  measured by implementation size; small internal modules are fine behind a simple interface.
- **Seam**: where an interface lives. **Adapter**: what fills it.
- **Locality**: each responsibility and each domain invariant has one owner; change, bugs
  and knowledge concentrate there instead of being re-enforced across callers.

- **Deletion test**: imagine deleting the module. If complexity vanishes, it was a
  pass-through — remove it. If it reappears across callers, it earns its keep.
- **The interface is the test surface**: tests cross the same seam callers do and survive
  internal refactors. Needing to test past it means the module is the wrong shape.
  Internal seams stay private; don't widen the interface so tests can substitute.
- **One adapter = hypothetical seam; two = real** (production + test counts). No port,
  layer or config for a variation nobody has.
- Accept dependencies instead of constructing them inside domain logic; keep assembly
  apart from behaviour. Return results instead of mutating; isolate side effects.

These rules apply on their own. For real design work — deepening a module, placing a
seam, shaping an interface — load the `codebase-design` skill for the full vocabulary,
dependency categories and the design-it-twice pattern. If the project has `GLOSSARY.md`
or `docs/adr/`, use its domain terms; don't contradict an ADR without raising it, and
record the outcome if it changes.

### Make the change easy, then make the easy change

Before writing code, understand the affected module — interface, callers, invariants,
dependencies — and find where the change belongs. If the structure doesn't accommodate it
cleanly, refactor first as its own behaviour-preserving step, tests green, then make the
change. That refactor is part of the task and already authorized: never defer it as
"out of scope" because a workaround would touch fewer files. This overrides any generic
"don't refactor adjacent code" guidance.

The boundary: refactor what the change passes through and its dependencies — concrete
friction, not speculative extensibility or unrelated cleanup. Debt seen elsewhere goes in
the final report, not the diff. Stop and propose first when the sound solution changes an
explicit requirement, a public interface or a persisted format, or ripples across modules
beyond the task.

When you deepen a module, replace the tests on the old shallow pieces with tests at the
new interface — after confirming the meaningful behaviours and failure cases are still
covered. Don't layer both.

Match the codebase's conventions, never its debt.

### Shapes that signal a broken design

A mode flag, special-case branch, conversion shim, near-duplicate function, parallel path
that bypasses a module, reach into another module's internals, type escape (`any`, cast,
`!`, ignore), swallowed error, or new code dropped in the nearest big file because the
data was there. Each is legitimate only when it models a real requirement or external
constraint with a clear owner. When one appears just to get past the existing structure
or make the requested example pass, the design is wrong: pause, find the mismatch,
refactor. Never weaken, skip or deeper-mock a test to dodge a rule the code broke.

### Before calling it done

Re-read the whole diff as the reviewer who will own it:

- Is every touched module deeper or shallower than before? Does each responsibility and
  invariant have one owner?
- Did the change add duplication, indirection or special cases that could be avoided?
- Were superseded paths and obsolete abstractions removed?
- Would the next agent find this by grepping the domain term?

Fix what fails. Report the design decisions, the refactors and why, the validation run,
and the debt you saw but left. Passing tests alone do not establish good design.

### The workspace

- Do not create worktrees or branches unless I ask, and once I have asked for one, it
  stays the project's workspace until I say otherwise.
