---
name: rest-api
description: Apply when designing or implementing REST API endpoints, routes, or controllers. Covers URL conventions, HTTP methods, status codes, error responses, pagination, versioning, authentication, security, caching, file uploads, health checks, and common API antipatterns. Framework-agnostic HTTP-level patterns. Project conventions always override these defaults.
---

# REST API Design

Match the project's existing API conventions. When uncertain, read 2-3 existing endpoints to infer the local style. Check for OpenAPI specs, existing error response formats, and authentication patterns. These defaults apply only when the project has no established convention.

Generic HTTP reference — the methods/status-code table, versioning strategies, auth mechanisms, caching headers, async patterns, and file uploads — lives in `references/http-reference.md`. Load it when needed.

## Never rules

These are unconditional. They prevent security vulnerabilities, broken contracts, and common API design mistakes regardless of project style.

- **Never use singular nouns for collection endpoints.** Use `/users`, not `/user`. Mixing singular and plural creates ambiguity — clients have to guess whether the endpoint is `/user/123` or `/users/123`. A consistent plural convention means the same base path serves both the collection (`GET /users`) and individual resources (`GET /users/123`).
- **Never nest resources deeper than 3 levels.** `/customers/123/orders/456/items` is the limit. Deeper nesting increases coupling and URL complexity. If the child has a globally unique ID, expose it as a top-level resource.
- **Never use verbs in URL paths for CRUD operations.** `POST /users/123/delete` duplicates what HTTP methods already express and makes the API unpredictable — clients can't know whether to use `POST /users/delete` or `DELETE /users`. Use `DELETE /users/123`. Verbs are acceptable only for non-CRUD actions as sub-resource endpoints (`POST /charges/ch_123/capture`) or colon syntax (`POST /instances/my-vm:start`).
- **Never return only the first validation error.** Return all validation errors at once with field paths. Returning one at a time forces clients into frustrating fix-one-discover-another cycles.
- **Never use offset pagination on datasets exceeding 10K rows.** Performance degrades linearly with offset depth — the database scans and discards every skipped row, so deep pages get drastically slower. Use cursor-based pagination.
- **Never omit `Retry-After` on 429 responses.** Rate limit responses without `Retry-After` force clients to guess retry timing, causing thundering herds or aggressive polling.
- **Never verify webhook signatures against re-serialized JSON.** Re-serialization changes key order or whitespace, invalidating the signature. Always verify against the raw request body bytes.
- **Never expose sequential integer IDs for resources accessible across trust boundaries.** Sequential IDs enable enumeration attacks (BOLA/IDOR). Use UUIDs or other unpredictable identifiers for user-facing resources.
- **Never bind raw client input directly to internal models.** This enables mass assignment — attackers adding `is_admin: true` to request bodies. Use explicit allowlists of writable fields via DTOs or schemas.
- **Never trust user-supplied resource IDs without server-side ownership verification.** BOLA (Broken Object Level Authorization) is the #1 API vulnerability. Every endpoint receiving an object ID must verify the caller owns or has access to that resource.
- **Never use wildcard `*` for CORS `Access-Control-Allow-Origin` with credentials.** Browsers reject `Access-Control-Allow-Credentials: true` with wildcard origin. Validate the `Origin` header against an allowlist and reflect the specific origin.
- **Never expose internal error details in production responses.** Stack traces, SQL queries, file paths, and dependency versions give attackers a detailed map of your internals — database schema, framework versions with known CVEs, and directory structure for path traversal. Return generic messages externally; log details internally.
- **Never deploy an API without health check endpoints.** Without health probes, orchestrators (Kubernetes, AWS ELB) can't distinguish a crashed pod from a healthy one — traffic routes to dead instances, and there's no automated recovery. A simple `/livez` returning 200 takes minutes to add and prevents hours of debugging silent outages.
- **Never support TLS versions below 1.2.** TLS 1.0 and 1.1 have known vulnerabilities (BEAST, POODLE) and are deprecated by all major cloud providers and PCI DSS. Require TLS 1.2 minimum, prefer 1.3.
- **Never omit security headers from API responses.** Missing `Strict-Transport-Security` allows SSL-stripping attacks on first visit. Missing `X-Content-Type-Options: nosniff` lets browsers reinterpret response content types, enabling XSS. Missing `Cache-Control: no-store` on authenticated endpoints means sensitive data persists in browser and proxy caches.

## Resource design

Use plural nouns with lowercase letters. For multi-word segments, pick one convention and apply it everywhere — kebab-case (`/payment-intents`) is the web standard, but snake_case (`/payment_intents`) and camelCase are acceptable if consistent.

Nest only when the child's lifecycle is coupled to the parent and its ID is scoped to that parent:

```
GET /customers/cus_8a3x/addresses       → Nested: addresses belong to a customer
GET /sales-orders/ord_5273gh             → Top-level: globally unique ID
```

For actions that don't map to CRUD, two patterns dominate:

```
# Sub-resource endpoint (Stripe model — most widely adopted)
POST /v1/charges/ch_123/capture HTTP/1.1

# Colon syntax (Google AIP-136 — cleaner for many custom methods)
POST /v1/instances/my-vm:start HTTP/1.1
```

Use standard CRUD first. When an action doesn't fit, sub-resource endpoints are safest for public APIs. Colon syntax is cleaner but less familiar to most developers.

**Query parameters** for filtering and sorting:

```
GET /products?category=electronics&price_gt=10&price_lt=100 HTTP/1.1
GET /tickets?sort=-priority,created_at&limit=20 HTTP/1.1
```

Comma-separated `sort` with `-` prefix for descending. Map filterable fields directly to query parameters. For complex filtering, use a filter expression string parameter.

## Error responses

Use RFC 9457 (Problem Details) as the base format, extended with a machine-readable `code` and optional `doc_url`:

```
HTTP/1.1 422 Unprocessable Content
Content-Type: application/problem+json

{
  "type": "https://api.example.com/errors/validation-error",
  "title": "Validation Failed",
  "status": 422,
  "code": "validation_error",
  "detail": "Two fields failed validation.",
  "doc_url": "https://docs.example.com/errors/validation-error",
  "errors": [
    {"detail": "must be a positive integer", "pointer": "#/age", "code": "invalid_type"},
    {"detail": "must be 'green', 'red' or 'blue'", "pointer": "#/profile/color", "code": "invalid_enum"}
  ]
}
```

Every error includes: a stable `code` for programmatic handling, a human-readable `detail` (which can change across versions), and field-level `errors[]` with JSON Pointer paths. Clients must key on `code`, never on `detail` text.

**Batch operations** — house convention: respond 207 Multi-Status with per-item results, even when all items succeed, to force clients to inspect individual results. (207 is a WebDAV status; plain 200 with per-item statuses is equally valid — pick one and stay consistent.)

```
HTTP/1.1 207 Multi-Status

{
  "results": [
    {"id": "item-1", "status": 201, "data": {"id": "new-123"}},
    {"id": "item-2", "status": 422, "error": {"code": "invalid_email", "detail": "Invalid email"}}
  ]
}
```

For batches exceeding ~1,000 items, accept with 202 and provide a polling endpoint.

## PATCH semantics

Three approaches exist — none has won:

| Approach | Mechanism | Null handling | When to use |
|----------|-----------|---------------|-------------|
| **JSON Merge Patch** (RFC 7396) | Send partial JSON | `null` means "delete field" — cannot set a field to null | Simple partial updates, no null-value fields |
| **JSON Patch** (RFC 6902) | Array of operations (add/remove/replace) | Explicit remove operation | Complex updates, array manipulation, atomic operations |
| **Field masks** (Google AIP-134) | `update_mask` parameter + merge patch body | Mask controls which fields update | APIs with many optional fields |

Most public APIs use custom lightweight PATCH — plain JSON with documented semantics. Whichever you choose, document explicitly: what happens when a field is `null`, which fields are updatable, and whether the operation is atomic.

```
# JSON Merge Patch — simple partial update
PATCH /users/123 HTTP/1.1
Content-Type: application/merge-patch+json

{"name": "New Name", "bio": null}
← name updated, bio deleted (null = remove)

# JSON Patch — explicit operations
PATCH /users/123 HTTP/1.1
Content-Type: application/json-patch+json

[
  {"op": "replace", "path": "/name", "value": "New Name"},
  {"op": "remove", "path": "/bio"}
]
```

## Pagination

Cursor-based is the right default. Offset-based is acceptable only for small (<10K), mostly static datasets where "jump to page N" is a hard requirement.

Response envelope — minimal metadata, boolean continuation flag:

```
GET /v1/customers?limit=20&starting_after=cus_4QFJ HTTP/1.1

HTTP/1.1 200 OK

{
  "data": [
    {"id": "cus_5RFL", "name": "Jane Doe"},
    {"id": "cus_6SGM", "name": "John Smith"}
  ],
  "has_more": true,
  "next_cursor": "cus_6SGM"
}
```

Avoid `total_count` by default — it requires an expensive `COUNT(*)` query. Make it opt-in if needed (`?include=total_count`).

Default page size: 20-50. Maximum: 100. Stripe defaults to 10 (max 100), GitHub 30 (max 100), Google Cloud 50.

Cursor-based pagination inherently handles real-time data — new inserts don't cause duplicates and deletes don't cause skips. Expire cursor tokens after ~3 days.

## Security

Beyond authentication, these patterns address the OWASP API Security Top 10:

**BOLA/IDOR prevention** — the #1 API attack vector. Every endpoint that receives a resource ID must verify ownership server-side. Never assume that because a user has a valid token, they can access any resource ID they supply:

```
# Wrong: trusts user-supplied ID without ownership check
GET /api/orders/ord_789 HTTP/1.1
Authorization: Bearer <valid_token>
← Returns order belonging to different user

# Correct: server verifies order belongs to authenticated user
GET /api/orders/ord_789 HTTP/1.1
Authorization: Bearer <valid_token>
← 404 if order doesn't belong to caller
```

**Mass assignment prevention** — use explicit input schemas that allowlist writable fields. Reject unexpected fields in request bodies. Never pass raw client input to database update operations.

**Input validation** — validate length, range, format, and type for all inputs at the API boundary. Constrain string inputs with patterns. Define request size limits and reject oversized payloads with 413.

**Security headers** on every response:

| Header | Value | Purpose |
|--------|-------|---------|
| `Strict-Transport-Security` | `max-age=63072000; includeSubDomains` | Force HTTPS |
| `X-Content-Type-Options` | `nosniff` | Prevent MIME sniffing |
| `Cache-Control` | `no-store` (authenticated endpoints) | Prevent sensitive data caching |
| `X-Frame-Options` | `DENY` | Prevent clickjacking |

**CORS** — validate `Origin` against an allowlist and reflect the specific origin. Set `Access-Control-Max-Age` for preflight caching. Never reflect arbitrary origins without validation.

**SSRF prevention** — when accepting URLs as input, validate against an allowlist of approved domains. Block internal network ranges (10.0.0.0/8, 172.16.0.0/12, 192.168.0.0/16, 127.0.0.1). Don't follow redirects to blocked hosts.

## Performance and reliability

Caching headers (`Cache-Control` + `ETag`, conditional requests, optimistic concurrency with `If-Match`) are covered in `references/http-reference.md`.

**Rate limiting** — token bucket is the best default for user-facing APIs. It allows traffic bursts while maintaining an average rate.

| Algorithm | Tradeoff | When to use |
|-----------|----------|-------------|
| **Token bucket** | Allows bursts, best default | User-facing APIs |
| **Fixed window** | Simplest, boundary burst problem | Internal APIs |
| **Sliding window** | Smooth enforcement, low memory | Strict rate control |

**Idempotency keys** — require an `Idempotency-Key` header on mutations where duplicate execution is costly (payments, order creation, provisioning); optional for cheap-to-repeat POSTs. Use V4 UUIDs. Store results keyed by the idempotency key; replay stored results on duplicate requests. Return an error if parameters differ from the original. Expire keys after 24 hours. GET and DELETE are inherently idempotent — keys are unnecessary.

```
POST /v1/charges HTTP/1.1
Idempotency-Key: 550e8400-e29b-41d4-a716-446655440000

{"amount": 2000, "currency": "usd"}
```

**Compression** — support gzip at minimum. JSON compresses 70-90%. Set a 1KB minimum threshold below which compression isn't applied. Always include `Vary: Accept-Encoding`.

## Health checks and observability

**Health endpoints** — required for orchestrated deployments:

```
GET /livez HTTP/1.1       → 200 if process is running (Kubernetes liveness)
GET /readyz HTTP/1.1      → 200 if ready to serve traffic (Kubernetes readiness)
GET /healthz HTTP/1.1     → 200 with dependency status (load balancer health)
```

```
HTTP/1.1 200 OK

{"status": "pass", "checks": {"database": "pass", "cache": "pass"}}
```

Health endpoints must not expose internal details (connection strings, versions, error messages). Keep liveness probes trivial — a liveness probe that checks the database causes cascading restarts during DB outages.

**Correlation IDs** — attach a unique identifier at the API gateway, propagate through all downstream services, return in every response:

```
HTTP/1.1 200 OK
X-Request-Id: f058ebd6-02f7-4d3f-942e-904344e8cde5
```

If the client provides an ID, preserve it. If not, generate UUID v4 at the entry point. Include in every log entry.

**OpenAPI specification** — maintain an OpenAPI 3.1+ spec as the source of truth for your API contract. Validate requests and responses against the spec in CI. Publish the spec for client SDK generation and documentation.

**Content negotiation** — support the `Accept` header. Return `406 Not Acceptable` for unsupported formats. Default to `application/json`. Custom media types (`application/vnd.myapi+json`) are justified only when different response structures are needed for the same resource — avoid them otherwise.

## Anti-patterns

- **Exposing database internals.** Column names as filter parameters, auto-increment IDs in URLs, database error messages in responses. All are information disclosure and coupling risks.
- **Pagination as afterthought.** Adding pagination to an existing endpoint is a breaking change. Design it from day one, even for small collections.
- **God endpoint.** A single endpoint accepting a `action` parameter to dispatch different operations. Use distinct URLs and HTTP methods.
- **Chatty APIs requiring N+1 calls.** If clients routinely need data from 3 endpoints to render one view, provide a composite endpoint or support field expansion (`?expand=customer,invoice`).
- **Version proliferation.** Maintaining 5+ active API versions. Use additive evolution (non-breaking changes) as the primary strategy. Reserve new versions for genuinely incompatible changes.
- **Webhooks without signatures.** Any webhook endpoint without cryptographic signature verification is vulnerable to spoofing. HMAC-SHA256 is the minimum.
- **Rate limits without headers.** Enforcing rate limits but not communicating them via response headers. Clients cannot implement backoff without `X-RateLimit-Remaining` and `Retry-After`.
- **Silently dropping unknown fields.** Accepting `{"amountt": 2000}` without error because `amountt` isn't a known field. Reject unexpected fields or at minimum log warnings.
- **Testing against mocks instead of contracts.** Mocks drift from reality. Validate requests and responses against the OpenAPI spec in CI using contract testing tools.
- **CORS wildcard with credentials.** Using `Access-Control-Allow-Origin: *` with `Access-Control-Allow-Credentials: true`. This is rejected by browsers and indicates a misunderstanding of the security model.
