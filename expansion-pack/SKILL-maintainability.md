---
name: drift-toolkit-maintainability
description: "Use when reviewing code quality: long files or functions, deep nesting, vague names, dead or stub code, duplicated logic, magic numbers, leftover debug code, docs that no longer match the code."
---

# Skill: Maintainability — Keep Code Small, Named, and Free of Debris

## Core Principle

**Code is read far more than it is written, and AI writes a lot.** Left unchecked, agents produce thousand-line files, vague names, commented-out blocks "just in case," stub functions that return nothing, and tangled fallback chains. None of it breaks the build — and all of it compounds into a codebase no one can change safely. This skill is the set of mechanical limits that keep generated code legible.

> This complements `SKILL-architecture.md` (which covers module boundaries and design patterns). Here the focus is size, naming, complexity, and debris.

---

## Size Limits

| Unit | Target | Hard Limit |
|------|--------|-----------|
| File | 300–400 lines | 1500 lines (refactor mandatory above this) |
| Function | < 50 lines | 100 lines |
| Nesting depth | ≤ 2 | 4 |
| Function parameters | ≤ 3 (else pass an object) | 5 |

```typescript
// ❌ FORBIDDEN — a 2000-line "god file" doing routing, parsing, and rendering
// ✅ REQUIRED — split by responsibility: routes.ts, parser.ts, renderer.ts
```

When a file crosses the limit, split by **responsibility**, not by arbitrary line count — extract the cohesive cluster (a class, a group of handlers, a sub-domain) into its own module.

---

## Naming: {Purpose}{Domain}{Type}

Names should state what a thing does, what it operates on, and what kind of thing it is. AI defaults to generic names (`handler`, `data`, `manager`, `utils`) that carry no information.

| Part | Examples |
|------|----------|
| **Purpose** | Generate, Sync, Load, Analyze, Translate, Validate |
| **Domain** | User, Order, Token, Component, Session |
| **Type** | Service, Workflow, Client, Adapter, Repository |

```typescript
// ❌ FORBIDDEN — generic, information-free
class Manager {}
function handleData(d: any) {}
const utils = {};

// ✅ REQUIRED — purpose + domain + type
class OrderSyncService {}
function validateUserInput(input: UserInput): ValidationResult {}
class TokenTranslationAdapter {}
```

---

## Complexity & Fallback Limits

Long fallback chains are where bugs hide. A function that tries six strategies and returns `null` if all fail tells you nothing about *what* went wrong.

```typescript
// ❌ FORBIDDEN — 6-strategy fallback chain that swallows every failure
static parse(content: string): unknown | null {
  try { return strategyA(); } catch {}
  try { return strategyB(); } catch {}
  try { return strategyC(); } catch {}
  // ...
  return null; // Which strategy failed? Why? Unknowable.
}

// ✅ REQUIRED — at most 2–3 focused strategies, then fail loudly
static parse(content: string): unknown {
  try { return strategyA(); }
  catch (a) {
    try { return strategyB(); }
    catch (b) {
      throw new Error(`Parse failed. A: ${a.message}; B: ${b.message}`);
    }
  }
}
```

- **Max 2–3 strategies** in a single function — more is a signal the design is wrong.
- **No nested try-catch blocks** whose only job is to mask the inner failure.
- **Always log which strategy succeeded** when more than one exists, and **fail explicitly** if none do.

---

## No Stub Code

A stub is a function that pretends to work. Either implement it fully or remove it — never leave a placeholder that returns fake or empty data.

```typescript
// ❌ FORBIDDEN — empty stub with a "this would..." comment
function compareSystems(a: System, b: System): Diff[] {
  // This would compare the two systems
  return [];
}

// ❌ FORBIDDEN — handler wired to an unimplemented feature
case 'export-pdf':
  return await exportPdf(params); // exportPdf is not implemented

// ✅ REQUIRED — implement fully, or remove the function and its call sites entirely
```

For a not-yet-built feature, pick exactly one: **(1)** implement it, **(2)** remove all of its code and references, or **(3)** document it in a roadmap with no dangling code. Never ship option zero — a stub.

---

## Remove Dead Code Immediately

Version control is the safety net; the working tree is not an archive.

- Delete commented-out code — `git log` remembers it.
- Remove unused functions, imports, variables, and parameters.
- Delete `.bak` / `-old` / `-copy` files — they are debris, not backups.
- Drop dependencies you no longer import.

```typescript
// ❌ FORBIDDEN — "keeping it just in case"
// const oldCalc = (x) => x * 0.9; // replaced 2024, leaving for reference
const calc = (x: number) => x * discountRate;

// ✅ REQUIRED — delete it; the history has it
const calc = (x: number) => x * discountRate;
```

---

## Documentation That Stays True

- **JSDoc public APIs**: params, returns, `@throws`, and a usage example.
- **Comments explain *why*, not *what*** — the code already says what.
- **No invented facts**: never write a "Last Updated" date, version number, benchmark, or file/function reference you have not verified. AI hallucinates these confidently. If you state a date, use the real current date; if you reference a symbol or path, confirm it exists.

```typescript
// ❌ FORBIDDEN — comment restates the code, and the date is invented
// Last Updated: January 2025  ← fabricated
// increment i by one
i += 1;

// ✅ REQUIRED — explains the non-obvious reason
// Off-by-one guard: the API's page index is 1-based, ours is 0-based.
i += 1;
```

---

## Quick Self-Test

Before committing, ask:

- "Is any file over ~1500 lines or any function over ~100?" → Split it.
- "Could someone guess what this name does without opening it?" → If no, rename to {Purpose}{Domain}{Type}.
- "Does any function try more than 3 fallbacks or return `null` when they all fail?" → Collapse and fail loud.
- "Is there any commented-out code, unused import, or `.bak` file in this diff?" → Delete it.
- "Did I write any date, version, or reference I haven't actually verified?" → Verify or remove it.
- "Is there any function that returns fake/empty data with a 'this would…' comment?" → Implement or delete.
