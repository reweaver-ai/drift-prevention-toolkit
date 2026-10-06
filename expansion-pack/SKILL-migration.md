---
name: drift-toolkit-migration
description: "Use when migrating or modernizing code: converting to TypeScript, upgrading a framework or library, replacing a dependency, or moving legacy code. Incremental steps that each add value and keep the code working."
---

# Skill: Migration — Convert Legacy Code Incrementally, Add Value Every Step

## Core Principle

**A migration that only renames files adds zero value and often hides bugs.** Asked to "migrate this to TypeScript" (or to a new framework, API, or module system), AI agents tend to do the mechanical minimum — change the extension, sprinkle `any`, suppress the errors — producing code that compiles but is no safer than before. Every migration must *add value*: real types, real validation, real tests. And it must be **incremental** — never a big-bang rewrite.

> The examples below use JavaScript → TypeScript, the most common case. The same discipline applies to any migration (callback → async, REST → typed client, CommonJS → ESM, framework upgrades).

---

## The Two Non-Negotiables

1. **Incremental, never big-bang.** Migrate in small, independently shippable units. The codebase must build and pass tests after every step.
2. **Every step adds value.** Types *and* validation *and* test coverage — not just a passing compiler.

---

## Priority Order: Bottom-Up

Migrate leaf nodes first (things with no internal dependencies), then work upward. Typing a leaf makes everything that consumes it easier to type next.

| Phase | What | Why First / Last |
|-------|------|------------------|
| First | Pure utilities, constants, type/interface definitions, data models | No dependencies — safe, high leverage |
| Middle | Services, business logic, API clients, data access, state | Depends on the typed foundation above |
| Last | UI components, integration glue, scripts, legacy edges | Most dependencies; benefits from everything below being typed |

---

## Migrate by Adding Real Types

```typescript
// ❌ FORBIDDEN — "migration" that just renamed .js → .ts
function process(data) {        // implicit any, no safer than before
  return data.value;
}

// ❌ FORBIDDEN — any everywhere defeats the entire purpose
function process(data: any): any {
  return transform(data);
}

// ✅ REQUIRED — define the shape, type the boundary
interface ProcessInput { value: number; label: string }
function process(data: ProcessInput): ProcessedResult {
  return transform(data);
}
```

Define the **interface first**, then bind it:

```typescript
// ✅ Define the contract, then apply it
interface User { name: string; age: number }
const user: User = { name: 'Ada', age: 36 };
```

Modernize patterns *as part of* the migration, not as a separate pass:

```typescript
// ❌ Callback style carried over verbatim
function fetchUser(id, cb) { api.get(id, (e, d) => e ? cb(e) : cb(null, d)); }

// ✅ Async/await with a typed return
async function fetchUser(id: string): Promise<User> {
  return api.get<User>(id);
}
```

---

## Migration Pitfalls — All Forbidden

| Pitfall | Why It's Wrong | Do Instead |
|---------|----------------|-----------|
| Rename `.js` → `.ts`, ship | No types added; zero value, false sense of progress | Add real types to every signature |
| `any` to silence the compiler | Erases the safety you're migrating *for* | Use `unknown` + type guards, or define the type |
| `@ts-ignore` / `@ts-expect-error` to bury errors | Hides the real defect the migration surfaced | Fix the underlying type mismatch |
| Big-bang rewrite of everything at once | Unreviewable, unrevertable, breaks for days | Small units, green build after each |
| Dropping tests during the move | You can't tell if you broke behavior | Keep/raise coverage (target > 80%) throughout |

```typescript
// ❌ FORBIDDEN — suppressing the error the migration just revealed
// @ts-ignore
const result = riskyOperation();

// ✅ REQUIRED — resolve it (type the source, or assert with a guard)
const result = riskyOperation();
if (!isResult(result)) throw new Error('riskyOperation returned an unexpected shape');
```

---

## Start Permissive, Tighten as You Go

Begin with relaxed compiler settings so the build stays green, then ratchet strictness up file-by-file as coverage grows — `noImplicitAny`, then `strictNullChecks`, then full `strict`. Tightening is itself an incremental migration; don't flip every flag on day one.

---

## Quick Self-Test

Before calling a migration step done, ask:

- "Did this step add real types/validation/tests — or did I just change the extension?"
- "Is the build green and are tests passing **right now**, before I move to the next unit?"
- "Did I reach for `any`, `@ts-ignore`, or a fallback to make an error go away?" → Fix the cause instead.
- "Am I migrating a leaf (safe) or a root (depends on un-migrated code)?" → Prefer leaves first.
- "Could I ship just this step to production on its own?" → If no, the unit is too big.
