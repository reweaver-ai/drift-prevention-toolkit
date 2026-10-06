---
name: drift-toolkit-type-safety
description: "Use when writing or reviewing TypeScript: any types, type assertions and double casts, non-null assertions, untyped external or API data, @ts-ignore. Zero tolerance for unjustified any."
---

# Skill: Type Safety — Zero Tolerance for `any`

## Core Principle

Every `any` type must be justified with documentation. Use proper types by default. Use `unknown` and type guards when the type is truly uncertain.

---

## The Rules

### Forbidden

```typescript
// ❌ Unjustified any
function process(data: any) { return data.value; }

// ❌ Function parameters with any
async function routeRequest(method: string, params: any) { ... }

// ❌ Return types with any
function getData(): Promise<{ elements: any[]; allElements: any[] }> { ... }

// ❌ Suppressing type errors
// @ts-ignore
const result = brokenOperation();
```

### Required

```typescript
// ✅ Use unknown + type guards
function process(data: unknown): ProcessedResult {
  if (!isValidData(data)) {
    throw new Error(`Invalid data: expected ValidData, got ${typeof data}`);
  }
  return transformData(data);
}

// ✅ Define proper interfaces
interface RequestParams {
  method: string;
  path: string;
  body?: Record<string, unknown>;
}

// ✅ Use discriminated unions for state
type RequestState =
  | { status: 'idle' }
  | { status: 'loading' }
  | { status: 'success'; data: ResponseData }
  | { status: 'error'; error: Error };
```

---

## Documented Exception Patterns

When `any` is genuinely unavoidable, use these pre-approved patterns:

### 1. External API Type Declarations

When the external API (VS Code, browser, third-party library) uses `any` in its official definitions:

```typescript
// ✅ ACCEPTABLE — External API constraint
// JUSTIFIED: VS Code API uses any for message payloads — from official API
declare function acquireVsCodeApi(): {
  postMessage(message: any): void; // eslint-disable-line @typescript-eslint/no-explicit-any
  getState(): any; // eslint-disable-line @typescript-eslint/no-explicit-any
  setState(state: any): void; // eslint-disable-line @typescript-eslint/no-explicit-any
};
```

**Requirements:**
- Must be in a `declare` statement for external APIs
- Must include `JUSTIFIED:` comment
- Must use `eslint-disable-line` for each instance
- Must validate types at runtime when consuming the API

### 2. Dynamic Import Variables

When using dynamic imports for lazy loading:

```typescript
// ✅ ACCEPTABLE — Dynamic import constraint
// JUSTIFIED: TypeScript cannot provide class types before dynamic imports resolve
// eslint-disable-next-line @typescript-eslint/no-explicit-any
let PreviewPanel: any;

try {
  const mod = await import('./views/PreviewPanel');
  PreviewPanel = mod.PreviewPanel;
} catch (error) {
  throw new Error(`Failed to import PreviewPanel: ${error.message}`);
}

// Types enforced at instantiation
let panel: InstanceType<typeof PreviewPanel> | null = null;
panel = new PreviewPanel(extensionUri, service);
```

**Requirements:**
- Only for variables assigned from dynamic imports
- Must include justification comment
- Must use `InstanceType<typeof X>` for instance variables
- Must wrap in try/catch

---

## Strict TypeScript Configuration

```json
{
  "compilerOptions": {
    "strict": true,
    "strictNullChecks": true,
    "noImplicitAny": true,
    "strictFunctionTypes": true,
    "noUncheckedIndexedAccess": true
  }
}
```

---

## Null/Undefined Handling

```typescript
// ❌ BAD — Loose checking
if (!user) return;

// ✅ GOOD — Explicit null check
if (user === null || user === undefined) {
  throw new Error('User is required');
}

// ✅ GOOD — Optional chaining for safe access
const name = user?.profile?.name;

// ✅ GOOD — Nullish coalescing for explicit optionals
const displayName = user.name ?? 'Anonymous';
// NOTE: Only for explicitly optional fields, NOT for masking missing required data
```

---

## Type Guards

```typescript
// ✅ Type guard function
function isUser(data: unknown): data is User {
  return (
    typeof data === 'object' &&
    data !== null &&
    'id' in data &&
    'email' in data &&
    typeof (data as User).id === 'string' &&
    typeof (data as User).email === 'string'
  );
}

// ✅ Usage
function processUser(input: unknown): UserResult {
  if (!isUser(input)) {
    throw new Error(`Expected User, got: ${JSON.stringify(input)}`);
  }
  // input is now typed as User
  return transform(input);
}
```

---

## Build Output Rules

**NEVER commit TypeScript compiled outputs to source directories:**
- No `.js` files alongside `.ts` files in source
- No `.js.map` files in source
- No `.d.ts` files in source (except `@types/`)

**ALWAYS:**
- Set `outDir` to `dist/` or `build/`
- Use `tsc -p tsconfig.json` (never bare `tsc`)
- Use `noEmit: true` for apps with bundlers

---

## Migration from JavaScript

### Do: Add Real Types

```typescript
// JavaScript
function add(a, b) { return a + b; }

// TypeScript — GOOD
function add(a: number, b: number): number { return a + b; }
```

### Don't: Just Rename and Add `any`

```typescript
// ❌ Pointless migration — defeats the purpose
function add(a: any, b: any): any { return a + b; }
```

### Don't: Suppress Errors

```typescript
// ❌ FORBIDDEN
// @ts-ignore
const result = legacyFunction(data);

// ✅ FIX the actual issue
const result = legacyFunction(data as LegacyInput);
// Or better: add proper types to legacyFunction
```

---

## Modern TypeScript Features to Use

- **Optional chaining** (`?.`) — safe nested access
- **Nullish coalescing** (`??`) — defaults for null/undefined only
- **`as const` assertions** — preserve literal types
- **Discriminated unions** — type-safe state machines
- **`satisfies` operator** — validate types without widening
- **Template literal types** — typed string patterns
