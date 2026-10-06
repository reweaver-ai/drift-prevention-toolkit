---
name: drift-toolkit-error-handling
description: "Use when writing or reviewing error handling: try/catch, promise rejections, empty catches, fallbacks, retries, logging, or errors that are swallowed, hidden or leaked to users. Every failure visible, actionable and traceable."
---

# Skill: Error Handling — Fail Fast, Fail Loud, Fail Transparent

## Core Principle

Every error must be immediately visible, actionable, and traceable. There are NO exceptions to this rule.

---

## The Required Pattern

Every error in the codebase must follow this three-part pattern:

```typescript
// STEP 1: Build a clear, contextual message
const msg = `[ComponentName] Failed to [action]: expected [X], got [Y]. Available: [options]`;

// STEP 2: Log with visual prefix
console.error('❌ ' + msg);

// STEP 3: Surface to user AND throw
notifyUser({ type: 'error', message: msg }); // Toast, notification, status bar
throw new Error(msg);
```

**Every error message must include:**
- **What** failed (the operation or function)
- **Why** it failed (expected vs. actual)
- **Where** it failed (component/function name)
- **How to fix** it (available options, expected format)

---

## Forbidden Patterns (with Corrections)

### 1. Silent Error Swallowing

```typescript
// ❌ FORBIDDEN — Error disappears
try { riskyOperation(); } catch (error) { }

// ❌ FORBIDDEN — Logged but not surfaced or thrown
try { riskyOperation(); } catch (error) { console.error(error); }

// ✅ REQUIRED
try {
  return riskyOperation();
} catch (error) {
  const msg = `Operation failed: ${error instanceof Error ? error.message : String(error)}`;
  console.error('❌ ' + msg);
  notifyUser({ type: 'error', message: msg });
  throw new Error(msg);
}
```

### 2. Skipping Errors with `continue`

```typescript
// ❌ FORBIDDEN — Hides which items are invalid and why
for (const item of items) {
  try { process(item); } catch { continue; }
}

// ✅ REQUIRED — Validate upfront, fail immediately
for (const item of items) {
  if (!isValid(item)) {
    throw new Error(`Invalid item: ${JSON.stringify(item)}. Expected valid structure.`);
  }
  process(item);
}
```

### 3. Fallback Values Masking Missing Data

```typescript
// ❌ FORBIDDEN — Masks that the color doesn't exist
function getColor(name: string, theme: ThemeConfig): Color {
  return theme.colors[name] || { r: 0.5, g: 0.5, b: 0.5 };
}

// ✅ REQUIRED — Fails with actionable context
function getColor(name: string, theme: ThemeConfig): Color {
  const color = theme.colors[name];
  if (!color) {
    throw new Error(
      `Color "${name}" not found. Available: ${Object.keys(theme.colors).join(', ')}`
    );
  }
  return color;
}
```

### 4. Defensive Checks That Skip

```typescript
// ❌ FORBIDDEN — Silently skips invalid data
if (!value || typeof value !== 'string') {
  console.warn('Invalid value, skipping');
  continue;
}

// ✅ REQUIRED — Fails with diagnostic info
if (!value || typeof value !== 'string') {
  throw new Error(`Invalid value: ${JSON.stringify(value)}. Expected string, got ${typeof value}`);
}
```

### 5. Multiple Fallback Strategies

```typescript
// ❌ FORBIDDEN — Masks which strategy failed and why
let result = null;
try { result = strategy1(); } catch { }
if (!result) try { result = strategy2(); } catch { }
if (!result) result = strategy3();
return result;

// ✅ REQUIRED — Maximum 2-3 strategies, fail explicitly
try {
  return primaryStrategy();
} catch (e1) {
  console.warn(`Primary strategy failed: ${e1.message}. Trying fallback.`);
  try {
    return fallbackStrategy();
  } catch (e2) {
    throw new Error(
      `All strategies failed. Primary: ${e1.message}. Fallback: ${e2.message}`
    );
  }
}
```

### 6. Workarounds Hiding Root Causes

```typescript
// ❌ FORBIDDEN — Substitutes a default instead of fixing the source
if (property === undefined) {
  property = defaultValue;
}

// ✅ REQUIRED — Surfaces the broken data source
if (property === undefined) {
  throw new Error(`Required property is undefined. Data source is invalid.`);
}
```

---

## Acceptable Patterns (Limited Exceptions)

These are the ONLY cases where non-throwing error handling is acceptable:

### 1. UI State Defaults for Optional Props

```typescript
interface ButtonProps {
  variant?: 'primary' | 'secondary'; // Explicitly optional in the interface
}
function Button({ variant = 'primary' }: ButtonProps) {
  // OK: variant is explicitly optional, default is for UI display
}
```

### 2. Empty State Messages

```typescript
if (items.length === 0) {
  return <EmptyState message="No items available" />;
  // OK: Shows data is missing, doesn't mask it
}
```

### 3. Infrastructure Constants

```typescript
const SIDEBAR_WIDTH = '300px'; // OK: UI layout, not a data fallback
```

**If you're unsure whether a pattern is acceptable, it's NOT. Default to throwing.**

---

## Custom Error Types

```typescript
class ValidationError extends Error {
  constructor(public field: string, message: string) {
    super(message);
    this.name = 'ValidationError';
  }
}

class NetworkError extends Error {
  constructor(message: string, public statusCode: number) {
    super(message);
    this.name = 'NetworkError';
  }
}

class DataSourceError extends Error {
  constructor(public source: string, message: string) {
    super(message);
    this.name = 'DataSourceError';
  }
}
```

---

## Async Error Handling

```typescript
// ✅ REQUIRED pattern for async functions
async function fetchData(): Promise<Data> {
  try {
    const response = await api.get('/data');
    return response;
  } catch (error) {
    if (error instanceof NetworkError) {
      throw new NetworkError(`API request failed (HTTP ${error.statusCode})`, error.statusCode);
    }
    throw new Error(`Unknown error: ${error instanceof Error ? error.message : String(error)}`);
  }
}

// ✅ REQUIRED: Async error boundaries at the top level
async function main() {
  try {
    await initializeApp();
  } catch (error) {
    console.error('❌ Application failed to start:', error);
    showFatalError(error instanceof Error ? error.message : 'Unknown error');
    process.exit(1);
  }
}
```

---

## Decision Flowchart

Before writing any error handling, ask:

1. **Does this hide an error?** → FORBIDDEN
2. **Does this mask missing data?** → FORBIDDEN
3. **Does this skip invalid input?** → FORBIDDEN
4. **Does this use a workaround?** → Fix root cause instead
5. **Will this error be visible to users?** → If no, FORBIDDEN
6. **Is this a UI-only optional default?** → Acceptable (document why)
