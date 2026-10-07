---
name: drift-toolkit-production-readiness
description: "Use when asked whether code is ready to ship, or to review, audit or harden a codebase for production. Start here: an 11-dimension go/no-go checklist covering security, errors, data, testing, observability, configuration, accessibility and performance."
---

# Skill: Production Readiness — 11-Dimension Checklist

## Core Principle

**Production ready from the first commit.** No "MVP shortcuts" or "we'll fix it later." Every feature must be secure, tested, observable, and maintainable.

---

## How to Run This Review

This checklist is the map, not the whole review. Each area below has a deep skill with the patterns to look for and the fixes that are acceptable. **Invoke each skill when you reach its area, before you judge that area.** Do not review an area from this checklist alone.

1. **Security:** invoke `drift-toolkit-security`.
2. **Error handling:** invoke `drift-toolkit-error-handling`, then `drift-toolkit-workarounds` for fallbacks and defensive code.
3. **Types:** invoke `drift-toolkit-type-safety` for any TypeScript.
4. **Data shown to users:** invoke `drift-toolkit-data-truth`.
5. **Async or shared state:** invoke `drift-toolkit-concurrency`.
6. **Architecture and code quality:** invoke `drift-toolkit-architecture`, then `drift-toolkit-maintainability`.
7. **Performance:** invoke `drift-toolkit-performance`.
8. **Testing:** invoke `drift-toolkit-testing`.
9. **Before you report or finish:** invoke `drift-toolkit-verification-checklist` and check your own changes against it.

Skip an area only when the codebase has nothing it covers, and say so in your report.

---

## Quick Go/No-Go

### 🔴 NO-GO (Blockers)
- Any critical security vulnerability
- Missing authentication/authorization on protected endpoints
- No error tracking or monitoring
- Missing data compliance (GDPR deletion, consent management)
- Missing audit logging

### 🟢 GO for MVP
- All security blockers resolved
- Basic monitoring and error tracking
- Core auth and API security
- Structured logging with correlation IDs

### 🟢 GO for Production Excellence
- All 11 dimensions fully addressed
- Comprehensive test coverage
- Full observability
- Complete compliance

---

## 1. Security

> Invoke `drift-toolkit-security` before reviewing this area.

### Authentication & Authorization
- [ ] Passwords hashed with bcrypt/Argon2 (NEVER plain text)
- [ ] JWT tokens with cryptographic signing and expiration
- [ ] Secure session cookies (httpOnly, secure, sameSite)
- [ ] Rate limiting on auth endpoints
- [ ] Authorization checks on all protected endpoints

### API Security
- [ ] Input validation on all endpoints (body, query, headers)
- [ ] CSRF protection on state-changing operations
- [ ] Parameterized database queries (no string concatenation)
- [ ] XSS prevention (sanitized output)
- [ ] Rate limiting on all API endpoints
- [ ] Security headers (CSP, X-Frame-Options, HSTS, noSniff)
- [ ] CORS with specific origin whitelist (no wildcards)
- [ ] Constant-time comparison for API keys/tokens

### Data Security
- [ ] Secrets in environment variables (never hardcoded)
- [ ] Encryption at rest and in transit
- [ ] Error messages sanitized (no stack traces in production)
- [ ] File uploads validated (type, size, content)

---

## 2. Architecture

> Invoke `drift-toolkit-architecture` before reviewing this area.

### Code Organization
- [ ] No file exceeds 2000 lines (target 300-400)
- [ ] Single responsibility per module
- [ ] Separated concerns (business logic, routing, data access, presentation)
- [ ] Dependency injection (no direct instantiation of services)
- [ ] Interfaces between service layers

### Dependencies
- [ ] No circular dependencies
- [ ] Regular dependency audits for vulnerabilities
- [ ] Clear dependency layers (shared → core → app)
- [ ] Explicit module type in package.json

---

## 3. Code Quality

> Invoke `drift-toolkit-maintainability` before reviewing this area.

### Complexity
- [ ] Functions: cyclomatic complexity < 15 (target < 10)
- [ ] Functions: < 100 lines (target 20-30)
- [ ] Parameters: ≤ 5 per function (use objects for more)
- [ ] Nesting: ≤ 4 levels deep

### Standards
- [ ] No code duplication (DRY — extract shared utilities)
- [ ] Consistent naming conventions
- [ ] Consistent code formatting (enforced by linter)
- [ ] No dead code, unused imports, or stub functions
- [ ] No `any` without documented justification

---

## 4. Performance

> Invoke `drift-toolkit-performance` before reviewing this area.

### Algorithms & Data Structures
- [ ] Appropriate data structures (Array vs Set vs Map)
- [ ] No unnecessary nested loops
- [ ] Expensive computations cached/memoized
- [ ] Resources lazy-loaded

### Memory
- [ ] Event listeners cleaned up on unmount
- [ ] Intervals/timeouts cleared
- [ ] No references to unused objects
- [ ] No memory leaks in long-running processes

### Network
- [ ] API calls batched where possible
- [ ] Appropriate caching (browser, CDN, service worker)
- [ ] Response compression enabled

---

## 5. Error Handling

> Invoke `drift-toolkit-error-handling` before reviewing this area.

- [ ] Fail fast, fail loud, fail transparent
- [ ] Every error logged, surfaced to UI, AND thrown
- [ ] Custom error types with context (ValidationError, NetworkError)
- [ ] No silent catch blocks
- [ ] No fallback values masking missing data
- [ ] Async errors properly propagated
- [ ] Error boundaries at top level

---

## 6. Testing

> Invoke `drift-toolkit-testing` before reviewing this area.

### Coverage
- [ ] Unit tests for business logic (target >80%)
- [ ] Integration tests for service interactions
- [ ] E2E tests for critical user workflows
- [ ] Security-focused tests (OWASP Top 10 scenarios)

### Infrastructure
- [ ] Tests run in CI/CD pipeline
- [ ] Test data is isolated and reproducible
- [ ] Flaky tests are fixed, not skipped

---

## 7. Observability

### Logging
- [ ] Structured logging (JSON format)
- [ ] Correlation IDs across requests
- [ ] Request/response logging at API boundaries
- [ ] Error logging with stack traces
- [ ] No secrets in logs

### Monitoring
- [ ] Health check endpoints
- [ ] Key metrics tracked (latency, error rate, throughput)
- [ ] Resource utilization monitored (CPU, memory, disk)
- [ ] Alerting configured for anomalies

### Tracing
- [ ] Distributed tracing for cross-service requests
- [ ] Performance profiling capabilities

---

## 8. Documentation

- [ ] API documentation (OpenAPI/Swagger)
- [ ] README with setup and running instructions
- [ ] Architecture documentation
- [ ] Runbooks for common operational tasks
- [ ] Incident response procedures
- [ ] Public APIs documented with JSDoc/KDoc

---

## 9. Compliance

### GDPR
- [ ] Data deletion endpoint implemented
- [ ] User consent management
- [ ] Data retention policies with automatic deletion
- [ ] Privacy policy and terms of service

### SOC 2
- [ ] Audit logging for security events
- [ ] Access controls and authorization
- [ ] Change management tracking

### Accessibility
- [ ] WCAG 2.1 AA compliance
- [ ] Semantic HTML (nav, main, header, footer)
- [ ] ARIA labels on interactive elements
- [ ] Full keyboard navigation
- [ ] Color contrast ratios (4.5:1 normal, 3:1 large text)
- [ ] Screen reader compatibility
- [ ] Visible focus indicators

---

## 10. Design Drift

- [ ] Design tokens for all values (colors, spacing, typography)
- [ ] No hardcoded design values in code
- [ ] Design system components used (not custom reimplementations)
- [ ] Component APIs match design system specs
- [ ] Visual regression testing configured
- [ ] Consistent spacing, layout, and responsive breakpoints

---

## 11. Severity Classification

When issues are found, classify and act:

| Severity | Meaning | Action |
|----------|---------|--------|
| 🔴 CRITICAL | Complete bypass/failure | BLOCKER — fix before deploy |
| 🟠 HIGH | Significant risk | Must fix for production |
| 🟡 MEDIUM | Quality impact | Important for production quality |
| 🟢 LOW | Nice-to-have | Can address post-launch |

---

## PR Review Checklist (Quick Version)

Every pull request must pass:

- [ ] Security: No vulnerabilities introduced
- [ ] Types: Proper types, no unjustified `any`
- [ ] Errors: Handled and surfaced (not swallowed)
- [ ] Performance: No leaks, efficient algorithms
- [ ] Maintainability: Readable, documented, testable
- [ ] Architecture: SOLID, proper separation
- [ ] Tests: Adequate coverage
- [ ] Documentation: Public APIs documented
