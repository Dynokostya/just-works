# HTTP Reference

Generic HTTP-level reference for the `rest-api` skill. House rules (Never rules, RFC 9457 error format, pagination thresholds, idempotency, health checks) live in SKILL.md.

## HTTP methods and status codes

```
Is the request malformed or unparseable?     → 400 Bad Request
Valid structure but fails business rules?     → 422 Unprocessable Content
Caller not authenticated?                     → 401 Unauthorized (+ WWW-Authenticate)
Authenticated but lacks permission?           → 403 Forbidden (or 404 to hide existence)
Resource doesn't exist?                       → 404 Not Found
Resource permanently removed?                 → 410 Gone
Conflicts with current state?                 → 409 Conflict
Rate limit exceeded?                          → 429 Too Many Requests (+ Retry-After)
Batch partially successful?                   → 207 Multi-Status (house convention — see SKILL.md)
Unexpected server error?                      → 500 Internal Server Error
Upstream service failing?                     → 502 Bad Gateway
Temporarily unavailable?                      → 503 Service Unavailable (+ Retry-After)
```

**400 vs 422:** Return 400 when the server cannot parse the request at all — malformed JSON, wrong Content-Type, missing required headers. Return 422 when the request is structurally valid but fails business rules — invalid email format, duplicate username, insufficient funds. If you don't want to distinguish, 400 is the safer default.

**401 vs 403:** Return 401 when credentials are missing or invalid. Return 403 when the caller is authenticated but lacks permission. Security pattern: return 404 instead of 403 for private resources to avoid confirming resource existence.

## Versioning

| Strategy | When to use | Example |
|----------|-------------|---------|
| **URI path** (most adopted) | Public APIs, simplicity | `/v1/users` |
| **Date-based header** (Stripe model) | Platform APIs, long-term stability | `API-Version: 2024-10-01` |
| **Query parameter** (Azure model) | Microsoft ecosystem | `?api-version=2024-01-01` |

For most public APIs, URI path versioning with major version only (`/v1/`) is the pragmatic default. Never use more than one versioning mechanism simultaneously.

**Breaking changes:** removing/renaming endpoints, parameters, or response fields; adding required parameters; changing field types; removing enum values; changing defaults; reducing rate limits.

**Non-breaking changes:** adding endpoints, optional parameters, response fields, response headers. Caveat: adding enum values for *output* parameters can break clients with strict deserialization — treat all output enum sets as extensible.

**Deprecation** uses two headers together:

```
HTTP/1.1 200 OK
Deprecation: @1751327999
Sunset: Sun, 30 Jun 2026 23:59:59 GMT
Link: <https://developer.example.com/migration>; rel="deprecation"
```

`Deprecation` (RFC 9745) takes a structured-field date — `@` followed by a Unix timestamp. `Sunset` (RFC 8594) keeps the HTTP-date format.

## Authentication and authorization

| Mechanism | Use when |
|-----------|----------|
| **API key** | Server-to-server, public data, developer onboarding |
| **OAuth 2.0 + PKCE** | Third-party access to user data, user consent required |
| **OAuth 2.0 Client Credentials** | Machine-to-machine with fine-grained scopes |
| **OAuth 2.0 Device Code** | CLI tools, IoT devices |
| **JWT bearer** | Stateless token validation across distributed services |

API keys authenticate the *application*, not the user. OAuth authenticates *users* through third-party apps. JWT is a *token format*, not a protocol — it cannot be revoked before expiry without a blocklist.

Many systems combine: API key at the gateway for identification and rate limiting, OAuth downstream for user-level authorization.

Design scopes around least privilege with `resource.action` convention: `users.read`, `users.delete`, `orders.write`. Keep scopes coarse-grained — fine-grained authorization logic belongs in the API layer, not the token.

Return rate limit headers with every response:

```
HTTP/1.1 200 OK
X-RateLimit-Limit: 5000
X-RateLimit-Remaining: 4987
X-RateLimit-Reset: 1372700873
```

## Caching

Combine `Cache-Control` with `ETag` for conditional requests:

```
GET /api/products/42 HTTP/1.1

HTTP/1.1 200 OK
Cache-Control: public, max-age=300, must-revalidate
ETag: "33a64df551425fcc55e4d42a148795d9f25f89d4"
Vary: Accept, Accept-Encoding
```

Subsequent requests use `If-None-Match` — a 304 response saves bandwidth. For writes, `If-Match` enables optimistic concurrency: return 412 Precondition Failed if the resource changed.

Use `public, max-age=N` for shared data, `private, no-cache` for user-specific data requiring revalidation, `no-store` for sensitive data.

## Async patterns

**Long-running operations** — for anything taking more than 10 seconds, return an operation resource immediately and let clients poll:

```
POST /v1/reports HTTP/1.1

HTTP/1.1 202 Accepted

{
  "operation_id": "op_123",
  "status": "running",
  "progress_percent": 0,
  "poll_url": "/v1/operations/op_123"
}
```

```
GET /v1/operations/op_123 HTTP/1.1

HTTP/1.1 200 OK

{
  "operation_id": "op_123",
  "status": "completed",
  "result": {"report_url": "/v1/reports/rpt_456"}
}
```

Include `Retry-After` to guide polling frequency. Provide cancel and delete operations. Expire completed operations after 24 hours minimum. Polling is preferred over callbacks — it works through firewalls, requires no public endpoint, and gives clients control over retry behavior.

**Webhooks** require three components: reliable delivery with retries, signature verification, and idempotent processing.

Signature verification — compute HMAC-SHA256 of `{timestamp}.{raw_body}` using the endpoint secret. Include the timestamp to prevent replay attacks:

```
POST /webhooks HTTP/1.1
X-Webhook-Signature: t=1614682800,v1=5257a869e7ecebeda32affa62cdca3fa51cad7e77a0e56ff536d0ce8e108d8bd

{"event": "order.completed", "data": {...}}
```

Verification: extract timestamp and signature, compute HMAC over `{timestamp}.{raw_body}`, compare using constant-time comparison, reject if timestamp exceeds 5 minutes (replay protection).

Best practices: return 2xx immediately before processing; enqueue work asynchronously; store processed event IDs for deduplication; return 4xx for permanent errors (stops retries), 5xx for transient errors (triggers retry).

## File uploads

| File size | Pattern | Mechanism |
|-----------|---------|-----------|
| < 5 MB | Direct upload | `multipart/form-data` to your API |
| 5–100 MB | Presigned URL | Client uploads directly to object storage |
| > 100 MB | Resumable/chunked | TUS protocol or cloud-native resumable upload |

**Presigned URLs** are the cloud-first pattern — the client gets a signed URL and uploads directly to S3/GCS, bypassing your API server entirely:

```
# Step 1: Client requests upload URL
POST /v1/uploads HTTP/1.1

{"filename": "report.pdf", "content_type": "application/pdf"}

HTTP/1.1 200 OK

{
  "upload_url": "https://storage.example.com/bucket/key?X-Amz-Signature=...",
  "expires_in": 3600,
  "resource_id": "file_abc123"
}

# Step 2: Client uploads directly to storage
PUT https://storage.example.com/bucket/key?X-Amz-Signature=... HTTP/1.1
Content-Type: application/pdf

<binary data>
```

For resumable uploads exceeding 100 MB, the TUS protocol (tus.io) is the emerging standard — used by Cloudflare, Supabase, and Vimeo.
