---
name: drift-toolkit-workarounds
description: "Use when a fix or existing code looks like a workaround: defensive checks that skip errors, fallback values that mask missing data, retries that hide failures, or a fix in the wrong layer. Fix root causes, not symptoms."
---

# Skill: Workarounds — Fix Root Causes, Not Symptoms

## Core Principle

Workarounds, hidden fixes, and defensive coding that masks problems are **NEVER acceptable**. Every issue must be fixed at its root cause.

---

## What Is a Workaround?

A workaround is any code that:

1. **Hides a problem** instead of fixing it
2. **Adds defensive checks** that skip invalid data instead of validating it at the source
3. **Uses fallback values** when data is missing instead of failing fast
4. **Fixes problems in the wrong layer** (e.g., patching data issues in the renderer instead of the parser)
5. **Adds complexity** to work around a simpler root cause

**The test**: If removing this code would expose a bug somewhere else, it's a workaround.

---

## The Workaround Detection Checklist

Before writing ANY code, ask these five questions:

| # | Question | If YES → |
|---|----------|----------|
| 1 | Is this fixing a symptom or the root cause? | Symptom = FORBIDDEN |
| 2 | Would this hide an error from users? | Hides error = FORBIDDEN |
| 3 | Is this adding complexity to work around a simpler issue? | Adds complexity = FORBIDDEN |
| 4 | Is this fixing the problem in the wrong layer? | Wrong layer = FORBIDDEN |
| 5 | Would this make debugging harder? | Harder to debug = FORBIDDEN |

**If ANY answer indicates a workaround, the code is FORBIDDEN. Fix the root cause instead.**

---

## Forbidden Patterns (with Corrections)

### 1. Defensive Checks That Skip Invalid Data

```typescript
// ❌ FORBIDDEN — Skips invalid items silently
function processItems(items: unknown[]) {
  for (const item of items) {
    if (!isValid(item)) {
      console.warn('Invalid item, skipping');
      continue; // Hides the data source bug
    }
    process(item);
  }
}

// ✅ REQUIRED — Validate at boundary, fail fast
function processItems(items: unknown[]) {
  for (const item of items) {
    if (!isValid(item)) {
      throw new Error(
        `Invalid item: ${JSON.stringify(item)}. Expected valid structure. Fix the data source.`
      );
    }
    process(item);
  }
}
```

### 2. Fallback Values Masking Missing Data

```typescript
// ❌ FORBIDDEN — Workaround: use default if missing
function renderComponent(component: Component) {
  const variant = component.variantValue || 'default'; // Why is it missing? Fix that.
  render(variant);
}

// ✅ REQUIRED — Fail when required data is missing
function renderComponent(component: Component) {
  if (!component.variantValue) {
    throw new Error(
      `Component "${component.name}" has no variantValue. Parser must extract variant values.`
    );
  }
  render(component.variantValue);
}
```

### 3. Fixes in the Wrong Layer

```typescript
// ❌ FORBIDDEN — Fixing a parser bug in the renderer
function renderLayout(component: Component) {
  // Problem: auto-layout components are 1px wide
  // Wrong fix: patch sizing in renderer
  if (!component.primaryAxisSizingMode) {
    component.primaryAxisSizingMode = 'AUTO'; // Hidden fix — WHY wasn't this set?
  }
}

// ✅ REQUIRED — Fix in the correct layer (the parser/creator)
function createComponent(spec: ComponentSpec): Component {
  if (spec.layoutMode) {
    return {
      ...spec,
      layoutMode: spec.layoutMode,
      primaryAxisSizingMode: 'AUTO',  // Set correctly at creation time
      counterAxisSizingMode: 'AUTO',
    };
  }
}
```

### 4. Hidden Fixes in Build Scripts

```typescript
// ❌ FORBIDDEN — Build script that patches broken code
// build.ts
function postBuild() {
  // "Fix" missing exports by adding them during build
  const content = readFile('dist/index.js');
  writeFile('dist/index.js', content + '\nexport { missingExport };');
}

// ✅ REQUIRED — Fix the actual source code
// src/index.ts
export { missingExport } from './missing-module';
```

### 5. "Just in Case" Defensive Code

```typescript
// ❌ FORBIDDEN — Defensive check "just in case"
function getUser(id: string): User {
  const user = db.findUser(id);
  if (!user) {
    // "Just in case" — but WHY would this be null?
    return { id: 'unknown', name: 'Unknown User' }; // Fake data!
  }
  return user;
}

// ✅ REQUIRED — Explicit about expectations
function getUser(id: string): User {
  const user = db.findUser(id);
  if (!user) {
    throw new Error(`User "${id}" not found in database.`);
  }
  return user;
}
```

---

## The Required Approach: Root Cause Fixing

When you encounter a problem:

1. **Identify the root cause** — Where is the data/state actually broken?
2. **Fix at the source** — Don't add defensive checks downstream
3. **Validate at boundaries** — Check data when it enters your system
4. **Fail fast** — Throw errors immediately when data is invalid
5. **Make it visible** — All errors must be visible to users

### Example: Complete Root Cause Analysis

**Problem**: Variant values are sometimes `undefined` in the renderer.

**Wrong approach** (workaround):
```typescript
// Renderer — masks the problem
const value = variant.value || 'default';
```

**Right approach** (root cause):
```
Step 1: WHERE does variant.value come from?
  → It's set by the parser in parseVariant()

Step 2: WHY is it sometimes undefined?
  → The parser doesn't handle elements without explicit variant attributes

Step 3: FIX at the source (the parser):
```

```typescript
function parseVariant(element: Element): Variant {
  const value = extractVariantValue(element);
  if (!value || typeof value !== 'string') {
    throw new Error(
      `Failed to extract variant value from element: ${JSON.stringify(element)}`
    );
  }
  return { value };
}
```

---

## Transparency Requirements

All fixes must be:

| Requirement | Meaning |
|-------------|---------|
| **Explicit** | Code clearly shows what it's doing |
| **Traceable** | Easy to find where and why the fix was applied |
| **Documented** | Comments explain the rationale |
| **Testable** | Can verify the fix works correctly |
| **Reversible** | Can undo if needed |
| **In the right layer** | Parser bugs fixed in parser, renderer bugs in renderer |

---

## Quick Self-Test

Before committing any fix, ask:

- "If I remove this code, would a bug appear somewhere else?" → It's a workaround. Fix the root cause.
- "Am I adding this check because the data *should* be valid but sometimes isn't?" → Fix why it's invalid.
- "Am I in the same module that produced the bad data?" → If no, you're in the wrong layer.
- "Does this make the error message disappear, or does it make the error impossible?" → Disappear = workaround. Impossible = real fix.
