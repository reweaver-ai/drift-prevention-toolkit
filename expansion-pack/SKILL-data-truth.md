---
name: drift-toolkit-data-truth
description: "Use when code displays or returns data: dashboards, lists, defaults, placeholders, sample or mock data, hardcoded values, fallbacks for missing data. Nothing fake reaches users; missing data fails or renders nothing."
---

# Skill: Data Truth — Never Fake What Should Come From Real Data

## Core Principle

**Display only data that actually exists. If the data isn't there, fail or render nothing — never invent a plausible-looking substitute.** AI agents reflexively fill gaps: a missing color becomes `#888`, an absent config becomes a sensible default, an empty result becomes mock rows. Each of these masks a real problem and ships a lie that *looks* correct. Truth in data means the output is always traceable to a real source — or it is honestly absent.

---

## The Rules

### Never Hardcode What Should Be Derived

```typescript
// ❌ FORBIDDEN — Hardcoded values masquerading as real data
function getThemeColor(name: string): string {
  return '#3366FF'; // Where did this come from? Nobody knows.
}

// ❌ FORBIDDEN — Placeholder data that looks real
function getUsers(): User[] {
  return [{ id: '1', name: 'John Doe', email: 'john@example.com' }]; // Fake
}

// ✅ REQUIRED — Sourced from real data structures
function getThemeColor(name: string, theme: Theme): string {
  const color = theme.colors[name];
  if (!color) {
    const msg = `Color "${name}" not found. Available: ${Object.keys(theme.colors).join(', ')}`;
    console.error('❌ ' + msg);
    throw new Error(msg);
  }
  return color;
}
```

### Constants Used as Fallbacks Are Still Hardcoded Data

A named constant does not make a fallback legitimate. `SPACING.DEFAULT` substituted for missing parsed data is the same lie as `'8px'` — it just hides better.

```typescript
// ❌ FORBIDDEN — Constant as a fallback for missing real data
const padding = parsed.spacing ?? SPACING.DEFAULT;
const color = data.color || COLORS.PRIMARY;

// ✅ REQUIRED — If the real value is missing, fail; don't substitute
if (parsed.spacing == null) {
  throw new Error(`Spacing missing for ${parsed.id}. Fix the data source, don't default it.`);
}
const padding = parsed.spacing;
```

### When Data Is Missing, Render Nothing — Not a Guess

```tsx
// ❌ FORBIDDEN — Inventing content to fill an empty state
function Profile({ user }: { user?: User }) {
  return <div>{user?.name ?? 'Anonymous User'}</div>; // Fabricated identity
}

// ✅ REQUIRED — Honest absence
function Profile({ user }: { user?: User }) {
  if (!user) return <EmptyState message="No user data available" />;
  return <div>{user.name}</div>;
}
```

`?? 'Anonymous User'`, `|| 0`, `?? []`, and `?? {}` are fabrication when the value should reflect reality. They are acceptable **only** for genuine UI display state (e.g. `state || 'idle'` for a visual toggle), never as a stand-in for absent business or domain data.

---

## The One Legitimate Default vs. The Masking Default

| Acceptable | Forbidden |
|-----------|-----------|
| A sensible default for **new** behavior (`maxRetries = 3`) | A default that **masks missing** data (`color ?? '#888'`) |
| UI-only display state (`status || 'idle'`) | Domain data fallback (`user ?? guestUser`) |
| Infrastructure layout constants (`SIDEBAR_WIDTH = 280`) | Design/content constants standing in for parsed values |
| Empty-state component when there's genuinely nothing | Fake rows / placeholder records to fill a table |

**Test**: *"If this default fires, has the user been shown something false?"* If yes, it's forbidden — throw or render empty instead.

---

## Why AI Gets This Wrong

The happy path always has data, so fabricated fallbacks never fire during the demo. They fire in production — when an API is slow, a field is renamed, a record is deleted — and at that moment the app confidently shows a wrong-but-plausible value instead of an error anyone could act on. Fabrication converts a loud, fixable failure into a silent, untraceable one.

---

## Quick Self-Test

Before committing, ask:

- "Is every value on screen traceable to a real source, or did I invent any of it?"
- "If I delete the underlying record, does this code show an error/empty state — or a convincing fake?"
- "Does any `||` / `??` / default here stand in for **domain data** that should exist?" → If yes, replace with a thrown error or an empty state.
- "Did I add example/placeholder data 'just so it renders'?" → Remove it; render nothing instead.
