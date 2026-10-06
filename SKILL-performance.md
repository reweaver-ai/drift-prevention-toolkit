---
name: drift-toolkit-performance
description: "Use when code is slow or resource-heavy, or before optimizing: loops over large data, repeated network or database calls, N+1 queries, memory growth, bundle size. Measure first; never trade correctness for speed."
---

# Skill: Performance — Measure First, Optimize Second

## Core Principle

**Never break correctness for performance. Never optimize without evidence.** The fastest code is code that works correctly. Broken code is infinitely slow.

---

## The Premature Optimization Trap

AI coding tools love to optimize. They will skip function calls "to save performance," add caching complexity without profiling, and break correctness to avoid "unnecessary" work. This is the single most common performance anti-pattern in AI-generated code.

### When Optimization Is FORBIDDEN

❌ Skipping function calls "to save performance" without profiling data
❌ Adding complexity to avoid "unnecessary" work without measurement
❌ Making assumptions about what's slow without evidence
❌ Breaking correctness for perceived performance gains
❌ Optimizing code that hasn't been identified as a bottleneck

### When Optimization Is REQUIRED

✅ Profiling shows a real, measured bottleneck
✅ Optimization doesn't break correctness
✅ Optimization doesn't add significant complexity
✅ Performance improvement is measurable and meaningful
✅ Optimization is reversible if it causes issues

### The Optimization Checklist

Before any optimization:

1. **Profile first** — use performance tools to identify the actual bottleneck
2. **Measure the baseline** — quantify current performance
3. **Preserve correctness** — never sacrifice functionality for speed
4. **Prefer caching over skipping** — cache expensive operations, don't skip them
5. **Document the rationale** — explain why optimization was needed and what was measured
6. **Make it reversible** — ensure you can revert if the optimization causes issues
7. **Measure the result** — verify the optimization actually improved performance

---

## Resource Management

Leaked resources are silent performance killers. AI-generated code frequently creates event listeners, intervals, and subscriptions without cleaning them up.

### Memory Leaks

```typescript
// ❌ FORBIDDEN — Interval never cleared
setInterval(() => {
  updateUI();
}, 1000);

// ✅ REQUIRED — Clean up on teardown
const intervalId = setInterval(() => {
  updateUI();
}, 1000);

// On component unmount / cleanup:
clearInterval(intervalId);
```

### Event Listeners

```typescript
// ❌ FORBIDDEN — Listener never removed
window.addEventListener('resize', handleResize);

// ✅ REQUIRED — Remove on cleanup
window.addEventListener('resize', handleResize);
// On teardown:
window.removeEventListener('resize', handleResize);
```

### Subscriptions and Observers

```typescript
// ❌ FORBIDDEN — Subscription never unsubscribed
const subscription = observable.subscribe(handler);

// ✅ REQUIRED — Unsubscribe on cleanup
const subscription = observable.subscribe(handler);
// On teardown:
subscription.unsubscribe();
```

**Rule**: Every `addEventListener` needs a corresponding `removeEventListener`. Every `setInterval` needs a `clearInterval`. Every `subscribe` needs an `unsubscribe`. No exceptions.

---

## Efficient Data Structures

Choose the right structure for the access pattern:

| Operation | Array | Set | Map | Object |
|-----------|-------|-----|-----|--------|
| Lookup by key | O(n) | O(1) | O(1) | O(1) |
| Check existence | O(n) | O(1) | O(1) | O(1) |
| Ordered iteration | ✅ | ❌ | ✅ | ❌ |
| Unique values | Manual | Built-in | N/A | N/A |

```typescript
// ❌ SLOW — Checking existence in array
const exists = items.find(item => item.id === targetId);

// ✅ FAST — Use Map for keyed lookups
const itemMap = new Map(items.map(item => [item.id, item]));
const exists = itemMap.get(targetId);
```

---

## DOM Performance

When working with browser code:

```typescript
// ❌ FORBIDDEN — Repeated DOM queries
function updateElements() {
  document.querySelector('.item').textContent = 'A';
  document.querySelector('.item').style.color = 'red';
  document.querySelector('.item').classList.add('active');
}

// ✅ REQUIRED — Cache the reference
function updateElements() {
  const item = document.querySelector('.item');
  if (!item) throw new Error('Element .item not found in DOM');
  item.textContent = 'A';
  item.style.color = 'red';
  item.classList.add('active');
}
```

- **Batch DOM updates** — use document fragments or requestAnimationFrame
- **Cache DOM queries** — never query the same selector repeatedly
- **Debounce/throttle** — for scroll, resize, and input events

---

## Quick Self-Test

Before committing performance-related code:

- "Did I profile before optimizing?" → If no, you're guessing. Profile first.
- "Does this optimization break any existing behavior?" → If yes, revert it.
- "Can I measure the improvement?" → If no, the optimization isn't justified.
- "Did I clean up every resource I created?" → If no, you have a memory leak.
