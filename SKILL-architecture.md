---
name: drift-toolkit-architecture
description: "Use when designing, reviewing or refactoring code structure: oversized files or classes, mixed responsibilities, tangled or circular dependencies, third-party services without a boundary, or before adding a new module. One reason to change per unit."
---

# Skill: Architecture — Clean, Focused, Maintainable

## Core Principles

- **Single Responsibility**: Each file/class/function does one thing well
- **Dependency Inversion**: Depend on abstractions, not concretions
- **Separation of Concerns**: Business logic, routing, data access, and presentation are separate
- **No God Objects**: Keep files focused and manageable

---

## File Size Limits — Enforced

| Metric | Target | Maximum |
|--------|--------|---------|
| File length | 300-400 lines | 1500 lines |
| Function length | 20-50 lines | 100 lines |
| Nesting depth | 2-3 levels | 4 levels |
| Function parameters | 3-4 | 5 (use objects for more) |
| Cyclomatic complexity | < 10 | < 15 |
| Fallback strategies | 1-2 | 3 |

When a file exceeds these limits, break it apart:

```typescript
// ❌ GOD OBJECT — handles routing, auth, billing, processing
class Orchestrator {
  handleRouting() { ... }
  processData() { ... }
  manageAuth() { ... }
  handleBilling() { ... }
}

// ✅ SEPARATED CONCERNS
class Router { handleRouting() { ... } }
class DataService { processData() { ... } }
class AuthService { manageAuth() { ... } }
class BillingService { handleBilling() { ... } }
```

---

## SOLID Principles

### Single Responsibility

Each class has one reason to change.

```typescript
// ❌ BAD — Parser also validates and transforms
class ComponentParser {
  parse() { ... }
  validate() { ... }
  transform() { ... }
}

// ✅ GOOD — Each class has one job
class ComponentParser { parse() { ... } }
class ComponentValidator { validate() { ... } }
class ComponentTransformer { transform() { ... } }
```

### Open/Closed

Open for extension, closed for modification. Use interfaces.

```typescript
// ✅ GOOD — New parsers don't require modifying existing code
interface Parser<T> {
  parse(input: string): T;
}

class ReactParser implements Parser<ReactComponent> { ... }
class VueParser implements Parser<VueComponent> { ... }
// Adding AngularParser doesn't touch ReactParser or VueParser
```

### Dependency Inversion

Depend on abstractions. Inject dependencies.

```typescript
// ❌ BAD — Concrete dependency
class UserService {
  private db = new PostgresDatabase(); // Tightly coupled
}

// ✅ GOOD — Abstract dependency via injection
interface IDatabase {
  query(sql: string, params: unknown[]): Promise<unknown>;
}

class UserService {
  constructor(private db: IDatabase) {} // Injected, swappable
}
```

### Interface in Core, Implementation in App

When core packages need application-specific behavior:

```typescript
// 1. Define interface in core package
// packages/core/src/IWorkflow.ts
export interface IWorkflow {
  execute(options: WorkflowOptions): Promise<Result>;
}

// 2. Implement in application
// apps/my-app/services/MyWorkflow.ts
export class MyWorkflow implements IWorkflow {
  async execute(options: WorkflowOptions): Promise<Result> { ... }
}

// 3. Inject at application startup
// apps/my-app/main.ts
import { setWorkflow } from '@myorg/core/workflow';
setWorkflow(new MyWorkflow());
```

**Key rule**: Core packages define interfaces. Applications provide implementations. Core never imports from applications.

---

## Import Path Rules

Replace `@myorg` below with your organization's npm scope (e.g., `@acme`, `@mycompany`).

### Cross-Module: Use Package Exports

```typescript
// ✅ CORRECT — Package exports
import { ApiClient } from '@myorg/core-api/ApiClient';
import { BaseParser } from '@myorg/core-parsers';
import { APP_CONFIG } from '@myorg/core-shared/config/app';

// ❌ FORBIDDEN — Deep relative paths
import { ApiClient } from '../../../packages/core/api/src/ApiClient';
```

### Same-Module: Relative Imports

```typescript
// ✅ CORRECT — Same module
import { helper } from '../utils/helper';
import { Config } from './config';
```

### Frontend Apps: Path Aliases

```typescript
// ✅ CORRECT — Path aliases from tsconfig/vite
import { Component } from '@shared/components/Component';
import { useAuth } from '@hooks/useAuth';
```

### Dependency Direction

```
Layer 0: shared (types, config, utilities)
    ↑
Layer 1: core services (parsers, transformers, adapters)
    ↑
Layer 2: application services (workflows, orchestration)
    ↑
Layer 3: applications (web apps, CLI tools, extensions)
```

**Never import downward.** Core packages never import from applications. Shared packages never import from core services.

---

## Design Patterns

### Factory Pattern — Centralize Object Creation

```typescript
function createParser(framework: string): Parser {
  switch (framework) {
    case 'react': return new ReactParser();
    case 'vue': return new VueParser();
    default: throw new Error(`Unsupported framework: ${framework}`);
  }
}
```

### Strategy Pattern — Interchangeable Algorithms

```typescript
interface SyncStrategy {
  sync(source: DesignData, target: CodeData): SyncResult;
}

class FullSyncStrategy implements SyncStrategy { ... }
class IncrementalSyncStrategy implements SyncStrategy { ... }

class SyncService {
  constructor(private strategy: SyncStrategy) {}
  execute(source: DesignData, target: CodeData) {
    return this.strategy.sync(source, target);
  }
}
```

### Repository Pattern — Abstract Data Access

```typescript
interface IUserRepository {
  findById(id: string): Promise<User | null>;
  save(user: User): Promise<void>;
}

// Business logic depends on interface, not database
class UserService {
  constructor(private repo: IUserRepository) {}
  async getUser(id: string): Promise<User> {
    const user = await this.repo.findById(id);
    if (!user) throw new Error(`User ${id} not found`);
    return user;
  }
}
```

---

## Code Organization Checklist

When creating new code, verify:

- [ ] File has a single, clear responsibility
- [ ] File is under 1500 lines (target 300-400)
- [ ] Functions are under 100 lines (target 20-50)
- [ ] Imports use package exports, not deep relative paths
- [ ] Dependencies are injected, not instantiated directly
- [ ] No circular dependencies
- [ ] No dead code, unused imports, or stub functions
- [ ] Public APIs are documented with JSDoc
- [ ] Complex logic has explanatory comments (why, not what)

---

## Stub Code Prevention

All code must be either fully implemented or completely removed. No middle ground.

### Forbidden Stub Patterns

```typescript
// ❌ FORBIDDEN — Empty function with comment
function processData(params: Params) {
  // This would process the data
}

// ❌ FORBIDDEN — Function returning hardcoded fake data
function extractUsers(source: string): User[] {
  return [{ name: 'fake', role: 'hardcoded' }];
}

// ❌ FORBIDDEN — Empty array/object with "would" comment
function compareItems(a: Item, b: Item): Difference[] {
  // This would compare the two items
  return [];
}

// ❌ FORBIDDEN — Handler for unimplemented feature
case 'unimplemented-feature':
  const result = await notYetBuilt(params);
  res.json(result);
  break;
```

### Required Approach

For features not yet implemented, choose ONE:

1. **Implement fully** — complete implementation with tests
2. **Remove completely** — delete all code and references
3. **Document in roadmap** — add to roadmap, remove all code

There is no fourth option. No TODOs, no placeholders, no "this would" comments left in production code.

---

## JavaScript Modernization

When writing JavaScript or TypeScript, use modern language features:

### Required Patterns

```typescript
// ✅ REQUIRED — const/let, never var
const immutableValue = 1;
let mutableValue = 2;

// ✅ REQUIRED — Arrow functions for concise expressions
const doubled = items.map(item => item.value * 2);

// ✅ REQUIRED — Template literals, not concatenation
const message = `User ${name} has ${count} items`;

// ✅ REQUIRED — Destructuring
const { name, age } = user;
const [first, ...rest] = items;

// ✅ REQUIRED — Async/await, not callbacks or raw promises
const data = await fetchData(id);

// ✅ REQUIRED — Optional chaining for safe access
const city = user?.address?.city;

// ✅ REQUIRED — Nullish coalescing for defaults
const timeout = config.timeout ?? 3000;

// ✅ REQUIRED — ES Modules
import { helper } from './helpers';
export { myFunction };
```

### Forbidden Legacy Patterns

```typescript
// ❌ FORBIDDEN — var
var x = 1;

// ❌ FORBIDDEN — String concatenation
const msg = 'User ' + name + ' has ' + count + ' items';

// ❌ FORBIDDEN — CommonJS (unless required by runtime)
const helper = require('./helpers');
module.exports = { myFunction };

// ❌ FORBIDDEN — Callbacks when async/await is available
fetchData(id, function(err, data) { ... });
```

---

## Documentation Discipline

### Code Comments

- Comments explain **why**, not **what**
- If code needs a comment to explain *what* it does, the code should be rewritten to be self-documenting
- Exception: complex algorithms or non-obvious business logic

```typescript
// ❌ BAD — Explains what (obvious from the code)
// Increment the counter
counter++;

// ✅ GOOD — Explains why (not obvious from the code)
// Counter resets after 3 failed attempts per rate-limiting policy
counter++;
```

### Public API Documentation

Document all public functions with JSDoc:

```typescript
/**
 * Validates a component specification against the schema.
 *
 * @param spec - The component specification to validate
 * @param options - Validation options (strict mode, custom rules)
 * @returns Validation result with errors and warnings
 * @throws {SchemaError} When the schema itself is invalid
 */
function validateSpec(spec: ComponentSpec, options?: ValidateOptions): ValidationResult {
  // Implementation
}
```

### Date Accuracy

All documentation dates must be accurate. When modifying a document, update the "Last Updated" field to the current date. Inaccurate dates undermine trust and break audit trails.

