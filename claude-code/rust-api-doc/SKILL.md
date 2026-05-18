---
name: rust-api-doc
description: Add comprehensive API documentation to Rust code for docs.rs. Use this skill when the user asks to "document this code", "add doc comments", "improve documentation", "make this docs.rs ready", "add rustdoc", or mentions preparing code for publication. Also trigger when the user is working on a library crate and mentions documentation, API clarity, or user-facing interfaces.
disable-model-invocation: true
---

# Rust API Documentation

Add comprehensive, user-friendly documentation comments to Rust code following docs.rs best practices.

## Core Principles

**Explain why, not what**: The code already shows _what_ it does. Documentation should explain _why_ it exists, _when_ to use it, and _how_ it fits into the larger picture.

**Examples for user-facing APIs**: Public APIs that users interact with directly should include examples. Internal helpers and obvious utilities don't need them.

**Cross-link related types**: Use `[TypeName]` to create clickable links in docs.rs. Help users discover related functionality.

**Document invariants and edge cases**: What assumptions does the code make? What happens in unusual situations?

## What to Document

### Module-level (`//!`)

- Purpose of the module
- Key concepts and relationships
- Usage examples for the primary workflow
- Links to important types

### Public structs and enums

- What the type represents (domain concept, not implementation)
- When to use it vs alternatives
- Key invariants or constraints
- Example for non-obvious usage

### Public functions

- What problem it solves (not just what it does)
- When to use it
- Errors it can return and why
- Examples for complex APIs

### Fields (when public)

- What the field represents
- Valid ranges or constraints
- How it relates to other fields

## Documentation Style

### Structure

````rust
/// One-line summary (ends with period).
///
/// Detailed explanation of why this exists and when to use it.
/// Multiple paragraphs are fine.
///
/// # Example
///
/// ```
/// use crate::Thing;
///
/// let thing = Thing::new();
/// thing.do_work();
/// ```
///
/// # Errors
///
/// Returns `Err` if the input is invalid.
///
/// # Panics
///
/// Panics if called before initialization.
````

### Sections to use

- `# Example` / `# Examples` — concrete usage
- `# Errors` — what can go wrong
- `# Panics` — when it panics
- `# Safety` — for unsafe code
- `# Invariants` — constraints that must hold

### Writing style

- Use present tense: "Returns the value" not "Will return"
- Be direct: "Creates a new instance" not "This function creates"
- Explain trade-offs: "Faster but uses more memory"
- Link related items: "See also [`OtherType`]"

## What NOT to Document

Skip documentation for:

- Private items (unless they're complex and need explanation for maintainers)
- Obvious getters/setters
- Standard trait implementations (Debug, Clone, etc.) unless they have special behavior
- Test functions

## Process

1. **Read the entire file** to understand the module's purpose and relationships
2. **Identify user-facing APIs** — public items that external users interact with
3. **Add module-level docs** explaining the big picture
4. **Document public types** with focus on why/when, not what
5. **Add examples** for non-obvious public APIs
6. **Cross-link related types** to help users discover functionality
7. **Verify** the documentation compiles with `cargo doc`

## Example Transformations

### Before

```rust
pub struct Task {
    pub id: String,
    pub status: Status,
}

pub fn run(task: &Task) -> Result<()> {
    // implementation
}
```

### After

````rust
/// A unit of work in the execution pipeline.
///
/// Tasks are created by [`expand_sweeps`] and executed by the scheduler.
/// Each task has a unique ID and tracks its execution status.
pub struct Task {
    /// Unique identifier, resolved from template (e.g., `"scf_U2"` from `"scf_U{u}"`).
    pub id: String,
    /// Current execution status.
    pub status: Status,
}

/// Execute a task and update its status.
///
/// Submits the task to its configured executor and polls until completion.
/// The task's working directory is created if it doesn't exist.
///
/// # Errors
///
/// Returns `Err` if:
/// - The executor fails to submit the job
/// - The working directory cannot be created
/// - The task times out (if `wall_time_secs` is set)
///
/// # Example
///
/// ```no_run
/// use workflow::Task;
///
/// let task = Task::new("scf_U2");
/// run(&task)?;
/// assert_eq!(task.status, Status::Completed);
/// ```
pub fn run(task: &Task) -> Result<()> {
    // implementation
}
````

## Common Patterns

### Explaining relationships

```rust
/// Concrete task instance after sweep expansion.
///
/// Created by [`expand_sweeps`] from [`TaskDef`]. All template placeholders
/// are resolved and sweep parameters are bound to specific values.
```

### Documenting invariants

```rust
/// Sweep parameter bindings that produced this instance.
///
/// Maps parameter names to their string values (e.g., `{"u": "2", "cutoff": "500"}`).
/// Empty for tasks without sweeps.
///
/// Used by attached tasks to inherit parent bindings during expansion.
pub bindings: HashMap<String, String>,
```

### Explaining design decisions

```rust
/// Working directories of tasks this task depends on.
///
/// Populated during the final pass of [`expand_sweeps`] after all tasks are expanded.
/// This deferred resolution allows dependencies to reference tasks defined later in the file.
```

## Verification

After documenting, run:

```bash
cargo doc --no-deps --document-private-items
```

Check for:

- Broken links (warnings about unresolved links)
- Malformed code blocks
- Missing backticks around type names

Open the generated docs in a browser to verify examples render correctly and links work.
