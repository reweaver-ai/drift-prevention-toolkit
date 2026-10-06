---
name: drift-toolkit-testing
description: "Use when writing, reviewing or fixing tests, or when code has none: unit and integration tests, mocks, snapshots, flaky or order-dependent tests, untested error paths. Test behavior, not implementation."
---

# Skill: Testing — Test Behavior, Not Implementation

## Core Principle

**Tests verify that code does the right thing, not how it does it.** Tests that mirror implementation details break on every refactor and provide zero confidence. Tests that verify behavior survive refactors and catch real bugs.

---

## The Rules

### Test Behavior, Not Implementation

```typescript
// ❌ FORBIDDEN — Tests implementation details
test('calls internal _calculateDiscount method', () => {
  const spy = jest.spyOn(cart, '_calculateDiscount');
  cart.checkout();
  expect(spy).toHaveBeenCalledWith(0.1);
});

// ✅ REQUIRED — Tests observable behavior
test('applies 10% discount for orders over $100', () => {
  const cart = new Cart([{ price: 120 }]);
  const result = cart.checkout();
  expect(result.total).toBe(108);
});
```

### Test Descriptions Document Intent

Test names should read like specifications. A failing test name should tell you what broke without reading the test body.

```typescript
// ❌ BAD — Vague, doesn't explain the scenario
test('handles error', () => { ... });
test('works correctly', () => { ... });
test('processData test', () => { ... });

// ✅ GOOD — Reads like a specification
test('throws ValidationError when email format is invalid', () => { ... });
test('returns empty array when no items match the filter', () => { ... });
test('retries failed API call up to 3 times before throwing', () => { ... });
```

### No Testing Mocks Instead of Behavior

Mocks should only simulate external boundaries (network, filesystem, databases). Never mock the unit under test.

```typescript
// ❌ FORBIDDEN — Mocking the thing you're testing
test('formats user name', () => {
  const formatter = new NameFormatter();
  jest.spyOn(formatter, 'capitalize').mockReturnValue('John');
  expect(formatter.format('john')).toBe('John');
  // This tests that the mock works, not the formatter
});

// ✅ REQUIRED — Test the actual unit, mock only external dependencies
test('formats user name with proper capitalization', () => {
  const formatter = new NameFormatter();
  expect(formatter.format('john doe')).toBe('John Doe');
});

// ✅ ACCEPTABLE — Mocking an external boundary
test('fetches user from API', async () => {
  const mockApi = { get: jest.fn().mockResolvedValue({ name: 'John' }) };
  const service = new UserService(mockApi); // Injected dependency
  const user = await service.getUser('123');
  expect(user.name).toBe('John');
});
```

---

## Test Types and When to Use Them

### Unit Tests — Business Logic

Test pure functions, transformations, validators, and domain logic in isolation.

```typescript
// ✅ Good unit test — tests a pure transformation
describe('PriceCalculator', () => {
  test('applies percentage discount', () => {
    const calc = new PriceCalculator();
    expect(calc.applyDiscount(100, { type: 'percent', value: 15 })).toBe(85);
  });

  test('throws when discount exceeds 100%', () => {
    const calc = new PriceCalculator();
    expect(() => calc.applyDiscount(100, { type: 'percent', value: 150 }))
      .toThrow('Discount cannot exceed 100%');
  });

  test('throws when price is negative', () => {
    const calc = new PriceCalculator();
    expect(() => calc.applyDiscount(-50, { type: 'percent', value: 10 }))
      .toThrow('Price must be non-negative');
  });
});
```

**Target**: >80% coverage of business logic. Every branch, every error path.

### Integration Tests — Service Interactions

Test that components work together correctly across boundaries.

```typescript
// ✅ Good integration test — tests real interaction between parser and validator
describe('Order Import Pipeline', () => {
  test('parsed order passes validation', () => {
    const parser = new OrderParser();
    const validator = new OrderValidator();
    
    const parsed = parser.parse(sampleOrderPayload);
    const result = validator.validate(parsed);
    
    expect(result.valid).toBe(true);
    expect(result.errors).toHaveLength(0);
  });

  test('malformed input produces actionable validation errors', () => {
    const parser = new OrderParser();
    const validator = new OrderValidator();
    
    const parsed = parser.parse(malformedPayload);
    const result = validator.validate(parsed);
    
    expect(result.valid).toBe(false);
    expect(result.errors[0].message).toContain('missing required property');
  });
});
```

### E2E Tests — Critical User Workflows

Test the most important user-facing paths end-to-end.

```typescript
// ✅ Good E2E test — tests a complete user workflow
describe('Checkout Workflow', () => {
  test('applies a discount code and charges the reduced total', async () => {
    const cart = await loadFixture('cart-two-items.json');
    
    const order = await checkout(cart, { discountCode: 'SAVE10' });
    
    expect(order).toEqual(
      expect.objectContaining({
        status: 'paid',
        subtotal: 120.0,
        discount: 12.0,
        total: 108.0,
      })
    );
  });
});
```

---

## Forbidden Test Patterns

### 1. Snapshot Test Overuse

Snapshots are acceptable ONLY for stable, visual output (rendered HTML, serialized config). Never for business logic results.

```typescript
// ❌ FORBIDDEN — Snapshot for business logic
test('calculates total', () => {
  expect(calculateOrder(items)).toMatchSnapshot();
  // What does the snapshot contain? Nobody knows without looking.
  // Any change auto-breaks, even correct ones.
});

// ✅ ACCEPTABLE — Snapshot for stable rendered output
test('renders error banner correctly', () => {
  const { container } = render(<ErrorBanner message="Something failed" />);
  expect(container.innerHTML).toMatchSnapshot();
});

// ✅ BETTER — Explicit assertions even for UI
test('renders error banner with message', () => {
  const { getByRole } = render(<ErrorBanner message="Something failed" />);
  expect(getByRole('alert')).toHaveTextContent('Something failed');
});
```

### 2. Test Interdependence

Each test must be fully independent. No shared mutable state, no execution order dependencies.

```typescript
// ❌ FORBIDDEN — Tests depend on execution order
let sharedUser: User;

test('creates user', () => {
  sharedUser = createUser({ name: 'Test' });
  expect(sharedUser.id).toBeDefined();
});

test('updates user', () => {
  // Fails if 'creates user' didn't run first
  updateUser(sharedUser.id, { name: 'Updated' });
});

// ✅ REQUIRED — Each test is self-contained
test('creates user', () => {
  const user = createUser({ name: 'Test' });
  expect(user.id).toBeDefined();
});

test('updates user', () => {
  const user = createUser({ name: 'Test' }); // Own setup
  const updated = updateUser(user.id, { name: 'Updated' });
  expect(updated.name).toBe('Updated');
});
```

### 3. Testing Framework Internals

Never test that a framework or library works. Test YOUR code's interaction with it.

```typescript
// ❌ FORBIDDEN — Testing that React works
test('useState updates state', () => {
  const { result } = renderHook(() => useState(0));
  act(() => result.current[1](1));
  expect(result.current[0]).toBe(1); // Yes, React works.
});

// ✅ REQUIRED — Testing your hook's behavior
test('useCounter increments and resets', () => {
  const { result } = renderHook(() => useCounter(0));
  act(() => result.current.increment());
  expect(result.current.count).toBe(1);
  act(() => result.current.reset());
  expect(result.current.count).toBe(0);
});
```

### 4. Tests Without Assertions

```typescript
// ❌ FORBIDDEN — No assertion, just "doesn't throw"
test('processes data', () => {
  processData(sampleInput); // What does this prove?
});

// ✅ REQUIRED — Explicit assertion on expected outcome
test('processes data into normalized format', () => {
  const result = processData(sampleInput);
  expect(result.normalized).toBe(true);
  expect(result.items).toHaveLength(3);
});
```

---

## Error Path Testing

Every error path documented in the code must have a corresponding test. This is especially important given the "Fail Fast, Fail Loud" philosophy.

```typescript
describe('PaymentParser error handling', () => {
  test('throws with context when payment type is unsupported', () => {
    const bad = { type: 'UNKNOWN', amount: 10 };
    expect(() => parser.parse(bad))
      .toThrow('Unsupported payment type "UNKNOWN". Supported: card, bank_transfer, wallet');
  });

  test('throws when required property is missing', () => {
    const incomplete = { type: 'card' }; // missing amount
    expect(() => parser.parse(incomplete))
      .toThrow('Missing required property "amount"');
  });

  test('error message includes available alternatives', () => {
    const badTheme = { colors: { primary: '#000' } };
    expect(() => getColor('secondary', badTheme))
      .toThrow('Available: primary');
  });
});
```

---

## Test Organization

### File Structure

```
src/
  services/
    PriceCalculator.ts
    PriceCalculator.test.ts      ← Unit tests co-located
  __tests__/
    integration/
      pipeline.test.ts           ← Integration tests
    e2e/
      checkout.test.ts           ← E2E tests
```

### Describe/Test Structure

```typescript
describe('PriceCalculator', () => {
  // Group by method or behavior
  describe('applyDiscount', () => {
    // Happy path first
    test('applies percentage discount correctly', () => { ... });
    test('applies fixed discount correctly', () => { ... });
    
    // Edge cases
    test('handles zero discount', () => { ... });
    test('handles maximum discount', () => { ... });
    
    // Error cases
    test('throws when discount is negative', () => { ... });
    test('throws when price is negative', () => { ... });
  });
});
```

---

## Test Fixtures and Factories

Use factories to create test data, not shared fixtures that accumulate bloat.

```typescript
// ✅ GOOD — Factory functions with sensible defaults
function createUser(overrides?: Partial<User>): User {
  return {
    id: 'user-1',
    name: 'Test User',
    email: 'test@example.com',
    role: 'member',
    ...overrides,
  };
}

// Usage in tests — only specify what matters for this test
test('admins can delete projects', () => {
  const admin = createUser({ role: 'admin' });
  expect(canDeleteProject(admin)).toBe(true);
});

test('members cannot delete projects', () => {
  const member = createUser({ role: 'member' });
  expect(canDeleteProject(member)).toBe(false);
});
```

---

## Test Infrastructure Rules

- [ ] Tests run in CI/CD pipeline — every commit, every PR
- [ ] Test data is isolated — no shared databases, no cross-test pollution
- [ ] Flaky tests are FIXED, not skipped — `test.skip` is a bug, not a solution
- [ ] Tests complete in reasonable time — unit tests < 10s, integration < 60s
- [ ] Test environment matches production configuration where possible

---

## Quick Self-Test

Before committing tests, ask:

- "If I refactor the implementation without changing behavior, do these tests break?" → If yes, you're testing implementation.
- "Can I tell what's wrong from the test name alone when it fails?" → If no, rename it.
- "Does this test add confidence, or just coverage?" → Coverage without confidence is waste.
- "Does each error path in the code have a corresponding test?" → If no, add them.
- "Are any tests dependent on other tests running first?" → If yes, make them independent.
