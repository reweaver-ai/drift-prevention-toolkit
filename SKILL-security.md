---
name: drift-toolkit-security
description: "Use when reviewing or writing anything security-sensitive: authentication, authorization, access control, user input, SQL or shell commands, secrets and keys, environment config, CORS, cookies, tokens, webhooks, file uploads, error messages shown to users."
---

# Skill: Security — Secure by Default

## Core Principle

All code must be secure by default. Security is not a feature — it's a baseline. Security vulnerabilities are never acceptable, even for "internal" tools or MVPs.

---

## Content Security Policy (CSP) Compliance

Modern web apps and browser extensions run under strict CSP. Code must work without runtime code generation.

**FORBIDDEN:**
```typescript
// ❌ Violates CSP script-src directive
new Function('return ' + expression);
eval(userInput);

// ❌ Runtime compilation (uses new Function internally)
const validator = new Ajv();
const validate = validator.compile(schema);
```

**REQUIRED:**
```typescript
// ✅ Pre-compile at build time
import validate from './validators/schema-validator.js'; // Generated at build
validate(data);

// ✅ Use static code only
const result = staticParser.parse(input);
```

---

## XSS Prevention

### DOM Manipulation

**FORBIDDEN:**
```typescript
// ❌ XSS vulnerability — user content interpreted as HTML
element.innerHTML = userInput;
element.innerHTML = `<div>${apiResponse.title}</div>`;
```

**REQUIRED:**
```typescript
// ✅ Safe text insertion — content is escaped automatically
element.textContent = userInput;

// ✅ Safe DOM construction
const div = document.createElement('div');
const title = document.createElement('h2');
title.textContent = apiResponse.title;
div.appendChild(title);
container.appendChild(div);

// ✅ When HTML structure is required — sanitize first
import DOMPurify from 'dompurify';
element.innerHTML = DOMPurify.sanitize(htmlContent);
```

### Template Output

```typescript
// ❌ FORBIDDEN in templates
<div dangerouslySetInnerHTML={{ __html: userContent }} />

// ✅ REQUIRED — React auto-escapes by default
<div>{userContent}</div>

// ✅ When HTML is needed — sanitize
<div dangerouslySetInnerHTML={{ __html: DOMPurify.sanitize(htmlContent) }} />
```

---

## SQL / NoSQL Injection Prevention

**FORBIDDEN:**
```typescript
// ❌ CRITICAL VULNERABILITY
const query = `SELECT * FROM users WHERE id = ${userId}`;
const query = `SELECT * FROM users WHERE name = '${userName}'`;
db.collection('users').find({ $where: `this.name == '${input}'` });
```

**REQUIRED:**
```typescript
// ✅ Parameterized queries
const query = 'SELECT * FROM users WHERE id = ?';
db.query(query, [userId]);

// ✅ ORM/query builder
const user = await userRepository.findOne({ where: { id: userId } });

// ✅ NoSQL — use typed queries
db.collection('users').find({ name: { $eq: sanitizedInput } });
```

---

## Input Validation

**Validate all inputs at system boundaries** — never trust external data.

```typescript
// ✅ Validate at API endpoint
function handleRequest(req: Request): Response {
  const input = validateInput(req.body);
  // input is now typed and safe
  return processInput(input);
}

// ✅ Type guard validation
function validateInput(data: unknown): ValidatedInput {
  if (!data || typeof data !== 'object') {
    throw new ValidationError('body', 'Request body must be an object');
  }
  if (!('name' in data) || typeof data.name !== 'string') {
    throw new ValidationError('name', 'Name must be a string');
  }
  if (data.name.length > 255) {
    throw new ValidationError('name', 'Name must be under 255 characters');
  }
  return data as ValidatedInput;
}

// ✅ Schema validation (pre-compiled)
import { validateUserInput } from './validators/user-input.js';
if (!validateUserInput(data)) {
  throw new ValidationError('body', formatValidationErrors(validateUserInput.errors));
}
```

---

## Secrets Management

**FORBIDDEN:**
```typescript
// ❌ Hardcoded secrets
const API_KEY = 'sk-abc123...';
const DB_PASSWORD = 'supersecret';
const token = 'ghp_xxxxxxxxxxxx';
```

**REQUIRED:**
```typescript
// ✅ Environment variables
const API_KEY = process.env.API_KEY;
if (!API_KEY) {
  throw new Error('API_KEY environment variable is required');
}

// ✅ .env file (gitignored)
// .env
API_KEY=sk-abc123...

// ✅ .gitignore
.env
.env.local
.env.production
```

**Never log secrets:**
```typescript
// ❌ FORBIDDEN
console.log('Connecting with key:', apiKey);
console.log('Config:', JSON.stringify(config)); // May include secrets

// ✅ REQUIRED
console.log('Connecting to API...');
console.log('Config loaded:', { endpoint: config.endpoint, region: config.region });
```

---

## API Security

### CORS Configuration

```typescript
// ❌ FORBIDDEN — Allows any origin
res.header('Access-Control-Allow-Origin', '*');

// ✅ REQUIRED — Specific origin whitelist
const allowedOrigins = process.env.CORS_ALLOWED_ORIGINS?.split(',') || [];
if (allowedOrigins.includes(origin)) {
  res.header('Access-Control-Allow-Origin', origin);
}
```

### API Key Comparison

```typescript
// ❌ FORBIDDEN — Timing attack vulnerable
if (providedKey === this.apiKey) { ... }

// ✅ REQUIRED — Constant-time comparison
import crypto from 'crypto';
if (crypto.timingSafeEqual(Buffer.from(providedKey), Buffer.from(this.apiKey))) { ... }
```

### Security Headers

```typescript
// ✅ REQUIRED — Use helmet.js or equivalent
import helmet from 'helmet';
app.use(helmet({
  contentSecurityPolicy: { directives: { defaultSrc: ["'self'"] } },
  hsts: { maxAge: 31536000, includeSubDomains: true },
  frameguard: { action: 'deny' },
  noSniff: true,
}));
```

### Rate Limiting

```typescript
// ✅ REQUIRED on all endpoints, especially auth
import rateLimit from 'express-rate-limit';
app.use('/api/auth', rateLimit({ windowMs: 15 * 60 * 1000, max: 10 }));
app.use('/api/', rateLimit({ windowMs: 15 * 60 * 1000, max: 100 }));
```

---

## Authentication

```typescript
// ❌ FORBIDDEN — Plain text passwords
if (password === user.password) { ... }

// ❌ FORBIDDEN — Simple string tokens
const token = `${userId}-${Date.now()}`;

// ✅ REQUIRED — Proper password hashing
import bcrypt from 'bcrypt';
const hash = await bcrypt.hash(password, 12);
const isValid = await bcrypt.compare(password, user.passwordHash);

// ✅ REQUIRED — JWT with proper signing
import jwt from 'jsonwebtoken';
const token = jwt.sign({ userId, role }, process.env.JWT_SECRET, { expiresIn: '1h' });
```

---

## File Upload Validation

```typescript
// ✅ REQUIRED — Validate before processing
function validateUpload(file: UploadedFile): void {
  const MAX_SIZE = 10 * 1024 * 1024; // 10MB
  const ALLOWED_TYPES = ['image/png', 'image/jpeg', 'application/pdf'];

  if (file.size > MAX_SIZE) {
    throw new ValidationError('file', `File too large: ${file.size} bytes. Max: ${MAX_SIZE}`);
  }
  if (!ALLOWED_TYPES.includes(file.mimetype)) {
    throw new ValidationError('file', `Invalid type: ${file.mimetype}. Allowed: ${ALLOWED_TYPES.join(', ')}`);
  }
}
```

---

## Pre-Commit Security Checklist

- [ ] No `new Function()` or `eval()` usage
- [ ] No `innerHTML` with user input
- [ ] All inputs validated at boundaries
- [ ] Secrets not committed to repository
- [ ] CSP-compliant code
- [ ] Dependencies audited (`npm audit`)
- [ ] Error messages don't leak stack traces or internal paths
- [ ] CORS uses specific origins, not wildcard
- [ ] Authentication uses proper hashing and JWT
- [ ] Rate limiting on all endpoints
