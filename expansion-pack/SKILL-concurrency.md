---
name: drift-toolkit-concurrency
description: "Use when code is async, parallel or shared between requests: promises, background jobs, caches, optimistic UI, retries, read-then-write updates, or anything that could run twice at once. Finds race conditions and state that can be corrupted."
---

# Skill: Concurrency — Race Conditions, Async Safety, State Integrity

## Core Principle

**Always ask: "What happens if this runs twice concurrently?"** AI-generated async code frequently introduces race conditions — interleaved state updates, missing guards on shared resources, and optimistic UI updates without rollback. Every async operation must be written with concurrency in mind.

---

## The Five-Question Concurrency Check

Before writing or reviewing any async code, ask:

| # | Question | If YES → |
|---|----------|----------|
| 1 | Can this function be called again before the previous call finishes? | Add guard or queue |
| 2 | Does this modify shared state (global, module-level, class instance)? | Serialize access |
| 3 | Can two operations read-then-write the same data? | You have a race condition |
| 4 | Does the UI update optimistically before confirmation? | Add rollback on failure |
| 5 | Are there multiple async steps that must all succeed or all fail? | Use transactions/sagas |

---

## Forbidden Patterns (with Corrections)

### 1. Unguarded Concurrent Calls

```typescript
// ❌ FORBIDDEN — Double-click calls this twice, second overwrites first
async function saveDocument(doc: Document): Promise<void> {
  const result = await api.save(doc);
  updateUI(result);
}

// ✅ REQUIRED — Guard against concurrent execution
let saveInProgress = false;

async function saveDocument(doc: Document): Promise<void> {
  if (saveInProgress) {
    console.warn('Save already in progress, ignoring duplicate call');
    return;
  }
  saveInProgress = true;
  try {
    const result = await api.save(doc);
    updateUI(result);
  } finally {
    saveInProgress = false;
  }
}
```

### 2. Read-Then-Write Race Conditions

```typescript
// ❌ FORBIDDEN — Two concurrent calls both read count=5, both write count=6
async function incrementCounter(): Promise<void> {
  const current = await db.get('counter');   // Both read 5
  await db.set('counter', current + 1);      // Both write 6 (should be 7)
}

// ✅ REQUIRED — Atomic operation or lock
async function incrementCounter(): Promise<void> {
  await db.atomicIncrement('counter', 1);
}

// ✅ ALTERNATIVE — Optimistic concurrency with version check
async function incrementCounter(): Promise<void> {
  const { value, version } = await db.getWithVersion('counter');
  const success = await db.setIfVersion('counter', value + 1, version);
  if (!success) {
    throw new Error('Counter was modified by another operation. Retry required.');
  }
}
```

### 3. Stale Closure State

```typescript
// ❌ FORBIDDEN — Closure captures stale state
function SearchComponent() {
  const [query, setQuery] = useState('');
  const [results, setResults] = useState([]);

  const search = async () => {
    const data = await api.search(query);
    setResults(data); // If user typed again while awaiting, this sets stale results
  };

  return <input onChange={e => { setQuery(e.target.value); search(); }} />;
}

// ✅ REQUIRED — Cancel stale requests
function SearchComponent() {
  const [query, setQuery] = useState('');
  const [results, setResults] = useState([]);
  const abortControllerRef = useRef<AbortController | null>(null);

  const search = async (searchQuery: string) => {
    // Cancel previous in-flight request
    abortControllerRef.current?.abort();
    const controller = new AbortController();
    abortControllerRef.current = controller;

    try {
      const data = await api.search(searchQuery, { signal: controller.signal });
      if (!controller.signal.aborted) {
        setResults(data);
      }
    } catch (error) {
      if (error instanceof DOMException && error.name === 'AbortError') {
        return; // Expected — request was superseded
      }
      throw error;
    }
  };

  return <input onChange={e => { setQuery(e.target.value); search(e.target.value); }} />;
}
```

### 4. Optimistic Updates Without Rollback

```typescript
// ❌ FORBIDDEN — UI shows success, but server may fail
function deleteItem(id: string) {
  setItems(items.filter(i => i.id !== id)); // Optimistic remove
  api.delete(id); // Fire-and-forget — no error handling
}

// ✅ REQUIRED — Optimistic update with rollback on failure
async function deleteItem(id: string) {
  const previousItems = [...items];
  setItems(items.filter(i => i.id !== id)); // Optimistic remove

  try {
    await api.delete(id);
  } catch (error) {
    setItems(previousItems); // Rollback
    const msg = `Failed to delete item "${id}": ${error instanceof Error ? error.message : String(error)}`;
    console.error('❌ ' + msg);
    notifyUser({ type: 'error', message: msg });
    throw new Error(msg);
  }
}
```

### 5. Uncontrolled Parallel Execution

```typescript
// ❌ DANGEROUS — 1000 parallel API calls will overwhelm the server
async function syncAllItems(items: Item[]): Promise<void> {
  await Promise.all(items.map(item => api.sync(item)));
}

// ✅ REQUIRED — Controlled concurrency
async function syncAllItems(items: Item[], concurrency = 5): Promise<void> {
  const queue = [...items];
  const workers = Array.from({ length: concurrency }, async () => {
    while (queue.length > 0) {
      const item = queue.shift();
      if (item) await api.sync(item);
    }
  });
  await Promise.all(workers);
}
```

---

## Async Patterns

### AbortController for Cancellation

Every long-running or supersedable async operation should support cancellation:

```typescript
// ✅ REQUIRED — Cancellable async operations
async function fetchWithTimeout(
  url: string,
  timeoutMs: number,
  signal?: AbortSignal
): Promise<Response> {
  const controller = new AbortController();
  const timeoutId = setTimeout(() => controller.abort(), timeoutMs);

  // Link external signal to internal controller
  signal?.addEventListener('abort', () => controller.abort());

  try {
    const response = await fetch(url, { signal: controller.signal });
    return response;
  } finally {
    clearTimeout(timeoutId);
  }
}
```

### Debounce for User Input

```typescript
// ✅ REQUIRED — Debounce rapid user actions
function debounce<T extends (...args: Parameters<T>) => void>(
  fn: T,
  delayMs: number
): (...args: Parameters<T>) => void {
  let timeoutId: ReturnType<typeof setTimeout> | null = null;
  return (...args: Parameters<T>) => {
    if (timeoutId) clearTimeout(timeoutId);
    timeoutId = setTimeout(() => fn(...args), delayMs);
  };
}

// Usage
const debouncedSearch = debounce(search, 300);
input.addEventListener('input', () => debouncedSearch(input.value));
```

### Mutex / Lock for Critical Sections

When multiple async operations must not interleave:

```typescript
// ✅ Simple async mutex
class AsyncMutex {
  private locked = false;
  private queue: Array<() => void> = [];

  async acquire(): Promise<() => void> {
    if (this.locked) {
      await new Promise<void>(resolve => this.queue.push(resolve));
    }
    this.locked = true;
    return () => {
      this.locked = false;
      const next = this.queue.shift();
      if (next) next();
    };
  }
}

// Usage
const mutex = new AsyncMutex();

async function criticalOperation(): Promise<void> {
  const release = await mutex.acquire();
  try {
    await readModifyWrite();
  } finally {
    release();
  }
}
```

---

## Event Ordering

### State Machine for Async Workflows

Complex async workflows should use explicit state machines to prevent invalid transitions:

```typescript
// ✅ REQUIRED — State machine prevents invalid transitions
type SyncState =
  | { status: 'idle' }
  | { status: 'syncing'; startedAt: number }
  | { status: 'success'; completedAt: number }
  | { status: 'error'; error: Error; failedAt: number };

class SyncManager {
  private state: SyncState = { status: 'idle' };

  async sync(): Promise<void> {
    if (this.state.status === 'syncing') {
      throw new Error('Sync already in progress. Cannot start concurrent sync.');
    }

    this.state = { status: 'syncing', startedAt: Date.now() };

    try {
      await performSync();
      this.state = { status: 'success', completedAt: Date.now() };
    } catch (error) {
      this.state = {
        status: 'error',
        error: error instanceof Error ? error : new Error(String(error)),
        failedAt: Date.now(),
      };
      throw error;
    }
  }
}
```

---

## Cleanup and Cancellation

Every async operation started in a component lifecycle must be cancellable on teardown:

```typescript
// ✅ REQUIRED — React cleanup pattern
function useAsyncData(id: string) {
  const [data, setData] = useState<Data | null>(null);

  useEffect(() => {
    const controller = new AbortController();
    let cancelled = false;

    async function load() {
      try {
        const result = await fetchData(id, { signal: controller.signal });
        if (!cancelled) setData(result);
      } catch (error) {
        if (!cancelled && !(error instanceof DOMException && error.name === 'AbortError')) {
          throw error;
        }
      }
    }

    load();

    return () => {
      cancelled = true;
      controller.abort();
    };
  }, [id]);

  return data;
}
```

---

## Quick Self-Test

Before committing async code, ask:

- "What happens if the user triggers this action twice rapidly?" → If both execute, add a guard.
- "What happens if the component unmounts while this is in-flight?" → If state updates, add cancellation.
- "Can two calls to this function interleave their read-then-write?" → If yes, you have a race condition.
- "If the server fails after the optimistic UI update, does the UI revert?" → If no, add rollback.
- "Are there any fire-and-forget awaits missing error handling?" → If yes, add try/catch.
