# Claude AI Assistant Guide
# Place this file as `CLAUDE.md` in your project root. Claude Code reads it automatically.

**For**: Claude AI assistants working in this codebase

---

## Skills: Use Them

This toolkit installs 14 skills (`./install-claude-skills.sh`, see README). They hold the detail behind the rules below. **Invoke the matching skill before you start; do not work from memory.**

- **Asked to review, audit or harden code, or whether it is ready to ship?** Start with `drift-toolkit-production-readiness`, then invoke each skill below that applies to what you find.
- **Before you say any task is done:** `drift-toolkit-verification-checklist`.

| Skill | Invoke when the work touches… |
|-------|-------------------------------|
| `drift-toolkit-security` | auth, access control, user input, SQL or shell, secrets, config, CORS, tokens, webhooks, uploads |
| `drift-toolkit-error-handling` | try/catch, rejections, fallbacks, retries, logging, errors shown to users |
| `drift-toolkit-workarounds` | defensive checks, fallback values, retries that hide failures, fixes in the wrong layer |
| `drift-toolkit-type-safety` | `any`, casts, non-null assertions, untyped external data, `@ts-ignore` |
| `drift-toolkit-data-truth` | displayed or returned data, defaults, placeholders, mock or sample data |
| `drift-toolkit-architecture` | file and module structure, responsibilities, dependencies, third-party boundaries |
| `drift-toolkit-maintainability` | long files or functions, naming, dead or stub code, duplication, stale docs |
| `drift-toolkit-concurrency` | async, parallel or shared state, background jobs, optimistic UI |
| `drift-toolkit-testing` | writing, fixing or reviewing tests, or code without tests |
| `drift-toolkit-performance` | slow paths, repeated calls, large data, memory, bundle size |
| `drift-toolkit-migration` | migrations, upgrades, TypeScript conversion, library replacement |
| `drift-toolkit-multi-agent` | several agents or sub-agents editing one codebase |

---

## 🚨 MANDATORY: Context-First Rule (NEVER SKIP)

**BEFORE writing ANY code, you MUST:**

1. **Read ALL relevant documentation** (including linked files)
2. **Create a todo list** with "Read documentation and gather context" as the FIRST item
3. **Complete documentation review** before starting implementation
4. **Search the codebase** for existing patterns before creating new code

**This rule exists because reactive coding wastes time and creates technical debt.**

---

## 🚨 CRITICAL: Zero Tolerance Policies

These patterns are **ABSOLUTELY FORBIDDEN** with **ZERO EXCEPTIONS**:

### 1. NO Partial Fixes

When fixing issues, fix **ALL** findings (CRITICAL, WARNING, INFO). Never say "I'll fix critical first" or "warnings later." Complete the entire task comprehensively.

### 2. NO Workarounds

Every problem must be fixed at its root cause. Never write defensive checks that skip errors, fallback values that mask missing data, or hidden fixes in the wrong layer.

```typescript
// ❌ FORBIDDEN
if (!data) { data = DEFAULT_VALUE; } // Masks the problem

// ✅ REQUIRED
if (!data) { throw new Error(`Data missing. Fix the data source.`); }
```

### 3. NO Stub Code

No empty functions with comments, fake data returns, or unimplemented handlers. Either implement fully or remove completely.

### 4. NO Compiled Outputs in Source

Never create `.js`, `.js.map`, or `.d.ts` files in source directories. These are build artifacts. Only create `.ts` source files.

### 5. NO Backward Compatibility

This is V1. Never implement compatibility logic, fallback behavior for old APIs, or default values that maintain old behavior.

### 6. NO Silent Errors

Every error must be:
1. **Logged**: `console.error('❌ ' + errorMessage)`
2. **Surfaced to UI**: notification, toast, or status message
3. **Thrown**: `throw new Error(errorMessage)` — stops execution

```typescript
// ❌ FORBIDDEN
try { riskyOp(); } catch (e) { console.error(e); } // Log-only

// ✅ REQUIRED: Three-point visibility
try { riskyOp(); } catch (error) {
  const msg = `Operation failed: ${error instanceof Error ? error.message : String(error)}`;
  console.error('❌ ' + msg);
  notifyUser({ type: 'error', message: msg });
  throw new Error(msg);
}
```

---

## Core Philosophy

**Rock Solid. Predictable. Transparent.**

1. **Truth in Data** — No fallbacks, no approximations. Fail fast if data is invalid.
2. **Fail Fast** — Validate at boundaries, surface errors immediately.
3. **Clean at Source** — Fix data at its origin, not at the consumer.
4. **Transparency** — Users see what's happening. No silent failures.
5. **Human-Centered** — System serves humans, augmented by AI.

---

## Type Safety

- **Zero tolerance for `any`** — use `unknown` + type guards
- When `any` is unavoidable, add: `// JUSTIFIED: <reason>` and `eslint-disable-line`
- Enable `strict: true` in tsconfig.json
- Never use `@ts-ignore` or `@ts-expect-error`

---

## Security

- **Never** use `eval()`, `new Function()`, or runtime code generation
- **Never** use `innerHTML` with untrusted data — use `textContent` or `createElement`
- **Never** concatenate user input into database queries
- **Never** hardcode secrets — use environment variables
- **Always** validate inputs at system boundaries
- **Always** use CSP-compliant patterns

---

## Code Quality

- Files: target 300-400 lines, max 1500
- Functions: target 20-50 lines, max 100
- Nesting: max 3-4 levels
- Single responsibility per class/function
- Dependency injection over direct instantiation
- No dead code, unused imports, or commented-out code
- Maximum 2-3 fallback strategies per function

---

## Performance & Resources

- **Never** optimize without profiling evidence — measure first
- **Never** break correctness for performance
- **Always** clean up event listeners (`removeEventListener`), intervals (`clearInterval`), subscriptions
- **Always** cache expensive operations — don't skip them

---

## Stub Code Prevention

All code must be fully implemented or completely removed:
- **No** empty functions with TODO/placeholder comments
- **No** functions returning hardcoded fake data
- **No** handler registrations for unimplemented features
- Either implement fully, remove entirely, or document in roadmap

---

## Modern Language Features

- Use `const`/`let` (never `var`)
- Use template literals (not string concatenation)
- Use destructuring, spread operator, optional chaining (`?.`), nullish coalescing (`??`)
- Use `async`/`await` (not callbacks or raw promises)
- Use ES Modules (`import`/`export`), not CommonJS unless required by runtime

---

## Documentation

- Comments explain **why**, not what
- Document public APIs with JSDoc
- Keep "Last Updated" dates accurate when modifying documents

---

## Import Patterns

Replace `@myorg` with your organization's npm scope (e.g., `@acme`, `@mycompany`).

```typescript
// ✅ Package imports for cross-module code
import { Service } from '@myorg/core-package/Service';

// ✅ Relative imports for same-module code
import { helper } from '../utils/helper';

// ❌ FORBIDDEN — Deep relative paths
import { Service } from '../../../packages/core/service';
```

---

## Dependency Management

**Before adding ANY dependency:**

1. **Check if it already exists** in the project
2. **Justify the addition** — document why it's needed
3. **Check size** — verify at bundlephobia.com
4. **Verify ESM support** and tree-shaking
5. **Check maintenance status** — active, secure, typed

**Size thresholds:**
- < 1MB: Generally acceptable
- 1-10MB: Requires justification
- > 10MB: Requires strong justification

---

## AI Coding Agent Behavior

1. **Verify before assuming** — search codebase for actual implementations
2. **Minimal changes** — reuse existing functions/patterns
3. **Search before creating** — find existing patterns first
4. **Question forbidden patterns** — mark violations, provide correct alternatives
5. **Complete verification** — run checklist before completing any task
6. **Never use `cd` to project root** — shell already starts there
7. **One writer per file** — Never spawn parallel agents that edit the same file. Parallel reads are safe; serialize all writes to the same file through a single agent. Spot-check agent results for silently reverted changes.

---

## Verification Checklist

**Before completing ANY code changes:**

### Security
- [ ] No `eval()`, `new Function()`, or `innerHTML` with untrusted data
- [ ] No hardcoded secrets
- [ ] Input validation at all boundaries

### Type Safety
- [ ] No unjustified `any` types
- [ ] All parameters and return types explicit

### Error Handling
- [ ] No silent fallbacks or empty catch blocks
- [ ] All errors: logged + surfaced to UI + thrown
- [ ] Error messages include context (what, why, where, how to fix)

### Code Quality
- [ ] Files < 1500 lines, functions < 100 lines
- [ ] No dead code, stubs, fake data, or commented-out code
- [ ] No compiled outputs in source directories
- [ ] Linter passes, build succeeds, tests pass

### Performance & Resources
- [ ] No optimizations without profiling evidence
- [ ] All event listeners, intervals, subscriptions cleaned up

### Modern Patterns
- [ ] Using const/let (no var), template literals, async/await
- [ ] Using ES Modules (no CommonJS unless required)
- [ ] No placeholder/TODO functions remaining

### Completeness
- [ ] ALL issues fixed (not just critical)
- [ ] Documentation updated with current dates
- [ ] Every fix at root cause, in the correct layer

---

## Quick Verification Commands

```bash
# Check for unjustified any types
grep -rn ": any" --include="*.ts" --include="*.tsx" | grep -v "JUSTIFIED" | grep -v "eslint-disable"

# Check for security violations
grep -rn "eval(\|new Function\|innerHTML" --include="*.ts" --include="*.tsx" --include="*.js"

# Check for silent error handling
grep -rn "catch.*{.*}" --include="*.ts" | grep -v "throw"

# Check for compiled outputs in source
find . -name "*.js" -not -path "*/node_modules/*" -not -path "*/dist/*" -not -path "*/build/*" \
  | while read js; do base="${js%.js}"; [ -f "${base}.ts" ] && echo "COMPILED: $js"; done

# Check for deep relative imports
grep -rn "\.\./\.\./\.\./packages" --include="*.ts" --include="*.tsx"

# Check for workaround patterns
grep -rn "workaround\|hack\|temporary fix\|kept for compatibility" --include="*.ts" --include="*.tsx" -i
```

---

**All rules are mandatory and enforced.**
