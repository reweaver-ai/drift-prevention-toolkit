---
name: drift-toolkit-verification-checklist
description: "Use before declaring any coding task done, and when checking a change or review for completeness: a run-before-done checklist covering errors, types, security, data, tests, concurrency and leftovers."
---

# Verification Checklist — Run Before Done

Use this checklist before completing ANY coding task. Code that fails verification must be fixed before completion.

---

## 🔴 Error Handling

- [ ] Every `catch` block logs, surfaces to UI, AND throws
- [ ] No empty catch blocks anywhere
- [ ] No `continue` used to skip errors in loops
- [ ] No `null`, `{}`, `[]` returned when data is missing
- [ ] No fallback values masking missing data (`value || default`)
- [ ] No log-only error handling (must also throw)
- [ ] Error messages include: what failed, why, where, how to fix
- [ ] Maximum 2-3 fallback strategies per function (all must fail explicitly if exhausted)

## 🔴 Type Safety

- [ ] No `any` without `// JUSTIFIED: <reason>` comment
- [ ] No `@ts-ignore` or `@ts-expect-error`
- [ ] All function parameters have explicit types
- [ ] All return types are explicit
- [ ] Interfaces defined for all data structures
- [ ] `unknown` + type guards used instead of `any` where possible

## 🔴 Security

- [ ] No `eval()` or `new Function()`
- [ ] No `innerHTML` with untrusted data
- [ ] No string concatenation in database queries
- [ ] No hardcoded secrets, API keys, or credentials
- [ ] All inputs validated at system boundaries
- [ ] Error messages don't leak internal paths or stack traces
- [ ] No wildcard CORS

## 🔴 Workaround Detection

- [ ] All fixes address root causes, not symptoms
- [ ] No defensive checks that skip invalid data (fix the data source)
- [ ] No hidden fixes in wrong layers (parser bugs in parser, renderer bugs in renderer)
- [ ] No "just in case" fallback values
- [ ] No code comments containing "workaround", "hack", "temporary fix", "kept for compatibility"
- [ ] Removing the fix would NOT expose a bug elsewhere (if it would, it's a workaround)

## 🔴 Multi-Agent Safety

- [ ] No parallel agents editing the same file
- [ ] Parent conversation not editing files delegated to agents
- [ ] Bulk renames handled by a single agent, not split across multiple
- [ ] Agent results spot-checked for silently reverted changes
- [ ] Changes committed before delegating multi-file edits to agents

## 🟠 Data Integrity

- [ ] No hardcoded design values (colors, spacing, typography)
- [ ] No constants used as fallbacks for parsed data
- [ ] No stub functions or placeholder implementations
- [ ] No fake/placeholder data pretending to be real
- [ ] Every displayed value traces to a real data source

## 🟠 Code Quality

- [ ] Files under 1500 lines (target 300-400)
- [ ] Functions under 100 lines (target 20-50)
- [ ] Nesting depth ≤ 4 levels
- [ ] No dead code (commented-out, unused functions/imports/variables)
- [ ] No backward compatibility shims
- [ ] No code with "workaround", "hack", or "temporary fix" comments
- [ ] DRY — no duplicated logic

## 🟠 Architecture

- [ ] Single responsibility per file/class/function
- [ ] Dependencies injected, not directly instantiated
- [ ] No circular dependencies between packages
- [ ] Imports use package exports (no deep relative paths)
- [ ] Concerns separated (business logic, routing, data, presentation)

## 🟡 Build & Deployment

- [ ] No TypeScript compiled outputs in source directories
- [ ] `tsconfig.json` has `outDir` set to `dist/` or `build/`
- [ ] Build scripts use `tsc -p tsconfig.json`
- [ ] Apps with bundlers use `noEmit: true`
- [ ] `.gitignore` excludes compiled outputs

## 🟡 Documentation

- [ ] "Last Updated" dates are current
- [ ] Public APIs documented with JSDoc
- [ ] Complex logic has explanatory comments (why, not what)
- [ ] README updated if adding new features

## 🟡 Testing

- [ ] New/changed code has test coverage
- [ ] All existing tests still pass
- [ ] No tests skipped or disabled

## 🟡 Performance & Resources

- [ ] No premature optimizations (profiling evidence required)
- [ ] No correctness sacrificed for performance
- [ ] All event listeners have corresponding removal on cleanup
- [ ] All setInterval/setTimeout cleared on teardown
- [ ] All subscriptions unsubscribed on cleanup
- [ ] No repeated DOM queries — references cached

## 🟡 Stub Code & Modernization

- [ ] No empty functions with TODO/placeholder comments
- [ ] No functions returning hardcoded fake data
- [ ] No handler registrations for unimplemented features
- [ ] Using const/let (never var)
- [ ] Using template literals (no string concatenation)
- [ ] Using async/await (no raw callbacks)
- [ ] Using ES Modules (import/export, not require/module.exports)

## 🟡 Completeness

- [ ] ALL issues fixed (critical, warnings, AND info)
- [ ] No items left "for later"
- [ ] Task is fully complete, not partially done

---

## Quick Commands

```bash
# TypeScript type checking
npx tsc --noEmit

# Lint
npm run lint

# Tests
npm test

# Check for compiled outputs in source
find . -name "*.js" -not -path "*/node_modules/*" -not -path "*/dist/*" \
  | while read js; do
      base="${js%.js}";
      [ -f "${base}.ts" ] && echo "COMPILED OUTPUT: $js";
    done

# Check for deep relative imports
grep -r "\.\./\.\./\.\./packages" --include="*.ts" --include="*.tsx"

# Check for unjustified any
grep -rn ": any" --include="*.ts" --include="*.tsx" | grep -v "JUSTIFIED" | grep -v "eslint-disable"

# Check for innerHTML
grep -rn "innerHTML" --include="*.ts" --include="*.tsx"

# Check for eval / new Function
grep -rn "eval(\|new Function" --include="*.ts" --include="*.tsx" --include="*.js"

# Check for empty catch blocks
grep -rn "catch\s*([^)]*)\s*{\s*}" --include="*.ts" --include="*.tsx"

# Check for silent fallbacks
grep -rn "return null\|return {}\|return \[\|\|\| defaultValue" --include="*.ts" --include="*.tsx" \
  | grep -v "// ACCEPTABLE\|// REQUIRED\|JUSTIFIED"

# Check for continue-skip patterns
grep -rn "continue.*skip\|continue.*error\|continue.*invalid" --include="*.ts" --include="*.tsx" -i

# Check for workaround indicators
grep -rn "workaround\|hack\|temporary fix\|kept for compatibility\|backward compat" \
  --include="*.ts" --include="*.tsx" -i

# Check for stub code patterns
grep -rn "TODO\|FIXME\|This would\|Not yet implemented\|placeholder" \
  --include="*.ts" --include="*.tsx" -i

# Check for fake data returns
grep -rn "return \[.*hardcoded\|return.*fake\|return.*mock" \
  --include="*.ts" --include="*.tsx" -i

# Check for var usage (should be const/let)
grep -rn "^\s*var " --include="*.ts" --include="*.tsx" --include="*.js"

# Check for CommonJS in non-config files
grep -rn "require(\|module\.exports" --include="*.ts" --include="*.tsx" \
  | grep -v "\.config\.\|jest\|webpack\|eslint"

# Check for leaked resources (addEventListener without removeEventListener)
grep -rn "addEventListener" --include="*.ts" --include="*.tsx" | wc -l
grep -rn "removeEventListener" --include="*.ts" --include="*.tsx" | wc -l
# These counts should roughly match

# Check for setInterval without clearInterval
grep -rn "setInterval" --include="*.ts" --include="*.tsx" | wc -l
grep -rn "clearInterval" --include="*.ts" --include="*.tsx" | wc -l
```
