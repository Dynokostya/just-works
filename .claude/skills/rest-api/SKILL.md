---
name: rest-api
description: Apply when designing or implementing REST API endpoints, routes, or controllers. Covers URL conventions, HTTP methods, status codes, error responses, pagination, versioning, authentication, security, caching, file uploads, health checks, and common API antipatterns. Framework-agnostic HTTP-level patterns.
---

# REST API Design

Project conventions override these defaults. Read 2-3 existing endpoints first, and check for an OpenAPI spec, the existing error format, and the authentication pattern.

`references/http-reference.md` holds the status code decision list (400 vs 422, 401 vs 403), versioning and deprecation headers, authentication mechanisms and scopes, caching and conditional requests, long-running operations, webhook signature verification, and file upload patterns. Read it when the task touches one of those.

## Never rules

- **Never return only the first validation error.** Return all errors at once with field paths.
- **Never use offset pagination on datasets over about 10K rows.** The database scans and discards every skipped row, so deep pages get slower. Use cursors.
- **Never omit `Retry-After` on 429 responses.**
- **Never verify webhook signatures against re-serialized JSON.** Verify against the raw request body bytes.
- **Never bind raw client input to internal models.** That allows mass assignment (`is_admin: true` in a body). Use DTOs or schemas that allowlist writable fields, and reject unknown fields.
- **Never trust a client-supplied resource ID without a server-side ownership check.** Broken object level authorization (BOLA, also called IDOR) is the most common API vulnerability. Respond 404 when the caller does not own the object, and use unpredictable IDs for resources that cross trust boundaries; opaque IDs slow enumeration but do not replace the check.
- **Never combine `Access-Control-Allow-Origin: *` with credentials.** Browsers reject it. Validate `Origin` against an allowlist and reflect the specific origin; set `Access-Control-Max-Age` for preflight caching.
- **Never expose internal error details in production responses.** Stack traces, SQL, file paths, and dependency versions go to logs, not clients.

## Resource design

Use plural, lowercase nouns, and one casing convention for multi-word segments (kebab-case is the web default). Express CRUD with HTTP methods, not verbs in paths: `DELETE /users/123`, not `POST /users/123/delete`. Nest only when the child's ID is scoped to its parent, and no deeper than 3 levels; otherwise expose it top-level:

```
GET /customers/cus_8a3x/addresses     nested: addresses belong to a customer
GET /sales-orders/ord_5273gh          top-level: globally unique ID
```

For non-CRUD actions, use a sub-resource endpoint (`POST /charges/ch_123/capture`, the safest for public APIs) or colon syntax (`POST /instances/my-vm:start`).

Filter and sort through query parameters: `GET /tickets?status=open&price_gt=10&sort=-priority,created_at&limit=20` (comma-separated `sort`, `-` prefix for descending).

## Error responses

Use RFC 9457 Problem Details (`application/problem+json`), extended with a stable machine-readable `code` and field-level `errors[]` using JSON Pointer paths. Clients key on `code`, never on `detail` text, which may change.

```
HTTP/1.1 422 Unprocessable Content
Content-Type: application/problem+json

{
  "type": "https://api.example.com/errors/validation-error",
  "title": "Validation Failed",
  "status": 422,
  "code": "validation_error",
  "detail": "Two fields failed validation.",
  "errors": [
    {"detail": "must be a positive integer", "pointer": "#/age", "code": "invalid_type"},
    {"detail": "must be 'green', 'red' or 'blue'", "pointer": "#/profile/color", "code": "invalid_enum"}
  ]
}
```

House convention for batch operations: respond 207 Multi-Status with a per-item result even when every item succeeds, so clients inspect each one. Plain 200 with per-item statuses is equally valid; stay consistent. Accept batches over roughly 1,000 items with 202 and a polling endpoint.

## PATCH

Document three things whichever style you pick: what `null` means, which fields are updatable, and whether the update is atomic. JSON Merge Patch (RFC 7396, `application/merge-patch+json`) is simplest, but `null` means "delete the field", so it cannot set a field to null. Use JSON Patch (RFC 6902) for array edits or atomic multi-step changes.

## Pagination

Cursor-based is the default; use offset only for small, mostly static datasets where "jump to page N" is required. Set a default and a maximum page size. Return minimal metadata and make `total_count` opt-in (`?include=total_count`), since it costs a `COUNT(*)`. Design pagination from the first version: adding it later breaks clients.

```
GET /v1/customers?limit=20&starting_after=cus_4QFJ

{"data": [{"id": "cus_5RFL"}, {"id": "cus_6SGM"}], "has_more": true, "next_cursor": "cus_6SGM"}
```

## Security

- Validate length, range, format, and type of every input at the API boundary, and reject oversized payloads with 413.
- Send security headers on every response: `Strict-Transport-Security: max-age=63072000; includeSubDomains`, `X-Content-Type-Options: nosniff`, and `Cache-Control: no-store` on authenticated endpoints.
- Require TLS 1.2 or higher; prefer 1.3.
- When accepting URLs as input (SSRF risk), validate against an allowlist of domains, block internal ranges (10.0.0.0/8, 172.16.0.0/12, 192.168.0.0/16, 127.0.0.0/8, link-local), and do not follow redirects to blocked hosts.

## Reliability

- **Rate limiting:** token bucket is the best default for user-facing APIs (allows bursts, enforces an average). Send `X-RateLimit-Limit`, `X-RateLimit-Remaining`, `X-RateLimit-Reset`, and `Retry-After` so clients can back off.
- **Idempotency keys:** require an `Idempotency-Key` header (UUID v4) on mutations where duplication is costly (payments, orders, provisioning). Store the result per key and replay it on duplicates, return an error if the parameters differ from the original, and expire keys after about 24 hours. GET and DELETE are already idempotent.
- **Health checks:** expose `/livez` (process is up) and `/readyz` (ready for traffic) for orchestrators. Keep liveness trivial: a liveness probe that checks the database causes cascading restarts during a database outage. Do not expose connection strings, versions, or error messages.
- **Correlation IDs:** keep the client's `X-Request-Id` if present, otherwise generate a UUID v4 at the entry point; propagate it downstream, log it, and return it in every response.
- **Contract:** maintain an OpenAPI 3.1+ spec as the source of truth and validate requests and responses against it in CI.
- **Content negotiation:** default to `application/json`, return 406 for unsupported `Accept` values, and use custom media types only when the same resource needs different response structures.

## Anti-patterns

- **Exposing database internals:** column names as filter parameters, auto-increment IDs, database error messages.
- **God endpoint:** one URL with an `action` parameter dispatching different operations. Use distinct URLs and methods.
- **Chatty APIs:** if clients need three endpoints to render one view, add a composite endpoint or field expansion (`?expand=customer,invoice`).
- **Version proliferation:** evolve additively; reserve new versions for incompatible changes.
- **Silently dropping unknown fields:** `{"amountt": 2000}` should be rejected, or at least logged.
