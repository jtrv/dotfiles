# Rust

## Lint gate
Default clippy under `-D warnings` only covers correctness/style/complexity/perf —
the idiom pressure lives in the opt-in groups. In `Cargo.toml`:

```toml
[lints.clippy]
pedantic = { level = "warn", priority = -1 }  # then `allow` the few that misfire, individually
# cherry-picked restriction lints — never enable the whole restriction group:
unwrap_used = "warn"
expect_used = "warn"
dbg_macro = "warn"
todo = "warn"
```

`priority = -1` on the group is load-bearing: individual overrides must outrank it.
Suppressions are `#[allow(clippy::lint_name)]` at the smallest scope with a
documented reason — never a crate-wide allow to get green, never a `#![allow]` of a
whole group.

## Named idioms
The un-lintable residue — lint rules beat prose, so these are only what clippy
can't judge:

- **Don't `.clone()` past the borrow checker.** Restructure ownership or borrow;
  clone is a decision, not an escape hatch (`redundant_clone` only catches the
  trivial cases).
- **Errors: `thiserror` enum in libraries, `anyhow` in binaries.** No stringly-typed
  `Box<dyn Error>` in public APIs.
- **Newtypes over primitive obsession** — `UserId(u64)`, not bare `u64`s crossing
  module boundaries.
- **Enums + exhaustive `match`** over bool/flag combinations; no wildcard arm on
  your own enums — adding a variant must be a compile error.
- **Concrete types before generics, generics before `dyn`.** No trait + single-impl
  ceremony.
- **`&str`/`&[T]` params over `String`/`Vec<T>`** unless the function actually
  takes ownership.

## Testing
Test with `cargo nextest run` (installed), not `cargo test`; doctests still need `cargo test --doc`.

## Pre-commit gate
Before committing, run `cargo fmt --all` and `cargo clippy --all-targets -- -D warnings` — the global pre-commit hook (`~/.config/git/hooks/pre-commit`) rejects commits failing either.
