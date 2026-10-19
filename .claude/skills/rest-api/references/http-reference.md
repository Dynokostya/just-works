# HTTP Reference

HTTP-level reference for the `rest-api` skill: the rules in SKILL.md (error format, pagination, security, idempotency, health checks) are not repeated here.

## Contents

- [Status codes](#status-codes)
- [Versioning and deprecation](#versioning-and-deprecation)
- [Authentication and authorization](#authentication-and-authorization)
- [Caching](#caching)
- [Long-running operations](#long-running-operations)
- [Webhooks](#webhooks)
- [File uploads](#file-uploads)

## Status codes

```
Malformed or unparseable request?             400 Bad Request
Valid structure but fails business rules?     422 Unprocessable Content
Caller not authenticated?                     401 Unauthorized (+ WWW-Authenticate)
Authenticated but lacks permission?           403 Forbidden (or 404 to hide existence)
Resource doesn't exist?                       404 Not Found
Resource permanently removed?                 410 Gone
Conflicts with current state?                 409 Conflict
Rate limit exceeded?                          429 Too Many Requests (+ Retry-After)
Batch partially successful?                   207 Multi-Status (house convention, see SKILL.md)
Unexpected server error?                      500 Internal Server Error
Upstream service failing?                     502 Bad Gateway
Temporarily unavailable?                      503 Service Unavailable (+ Retry-After)
```

**400 vs 422:** use 400 when the server cannot parse the request (malformed JSON, wrong Content-Type, missing required headers) and 422 when it parses but fails business rules (invalid email, duplicate username, insufficient funds). If you do not want to distinguish them, 400 is the safer default.

**401 vs 403:** 401 means credentials are missing or invalid; 403 means the caller is authenticated but not permitted. Return 404 instead of 403 for private resources so the response does not confirm they exist.

## Versioning and deprecation

| Strategy | When to use | Example |
|----------|-------------|---------|
| URI path | Public APIs, simplicity | `/v1/users` |
| Date-based header | Platform APIs, long-term stability | `API-Version: 2024-10-01` |
| Query parameter | Microsoft ecosystem | `?api-version=2024-01-01` |

URI path versioning with the major version only (`/v1/`) is the pragmatic default. Use one versioning mechanism, never several.

Breaking changes: removing or renaming endpoints, parameters, or response fields; adding required parameters; changing field types or defaults; removing enum values; reducing rate limits. Non-breaking: adding endpoints, optional parameters, response fields, or headers. Treat output enum sets as extensible, because a new value can break clients with strict deserialization.

Signal deprecation with two headers (RFC 9745 and RFC 8594):

```
Deprecation: @1688169599
Sunset: Sun, 30 Jun 2024 23:59:59 GMT
Link: <https://developer.example.com/migration>; rel="deprecation"
```

`Deprecation` is a structured-field date: `@` followed by a Unix timestamp. `Sunset` uses the HTTP-date format, and its weekday must match the date. The example values are the ones used in RFC 9745 section 4.

## Authentication and authorization

| Mechanism | Use when |
|-----------|----------|
| API key | Server-to-server, public data, developer onboarding |
| OAuth 2.0 + PKCE | Third-party access to user data with user consent |
| OAuth 2.0 client credentials | Machine-to-machine with scopes |
| OAuth 2.0 device code | CLI tools, IoT devices |
| JWT bearer | Stateless token validation across services |

API keys identify the application, not the user. JWT is a token format, not a protocol, and cannot be revoked before expiry without a blocklist. Systems often combine an API key at the gateway (identification, rate limiting) with OAuth downstream (user authorization).

Name scopes `resource.action` (`users.read`, `orders.write`) with least privilege, and keep them coarse: fine-grained authorization belongs in the API layer, not the token.

## Caching

Combine `Cache-Control` with `ETag`:

```
HTTP/1.1 200 OK
Cache-Control: public, max-age=300, must-revalidate
ETag: "33a64df551425fcc55e4d42a148795d9f25f89d4"
Vary: Accept, Accept-Encoding
```

Clients revalidate with `If-None-Match` and get a 304 when unchanged. For writes, `If-Match` gives optimistic concurrency: return 412 Precondition Failed if the resource changed. Use `public, max-age=N` for shared data, `private, no-cache` for user-specific data that needs revalidation, and `no-store` for sensitive data.

## Long-running operations

For work taking more than about 10 seconds, return `202 Accepted` with an operation resource the client polls:

```
HTTP/1.1 202 Accepted

{"operation_id": "op_123", "status": "running", "poll_url": "/v1/operations/op_123"}
```

`GET /v1/operations/op_123` returns `status` (`running`, `completed`, `failed`) and, when done, a `result` link. Send `Retry-After` to set the polling interval, support cancel and delete, and keep completed operations at least 24 hours. Prefer polling over callbacks: it works through firewalls and needs no public endpoint.

## Webhooks

Webhooks need retried delivery, signature verification, and idempotent processing.

- **Signature:** compute HMAC-SHA256 over `{timestamp}.{raw_body}` with the endpoint secret and send both, for example `X-Webhook-Signature: t=1614682800,v1=<hex>`. The receiver recomputes the HMAC over the raw bytes, compares in constant time, and rejects timestamps older than about 5 minutes to stop replays.
- **Receiver:** return 2xx immediately and process asynchronously. Store processed event IDs for deduplication. Return 4xx for permanent errors (stops retries) and 5xx for transient ones (triggers retries).

## File uploads

| File size | Pattern |
|-----------|---------|
| Under 5 MB | `multipart/form-data` direct to the API |
| 5-100 MB | Presigned URL: the client uploads straight to object storage |
| Over 100 MB | Resumable or chunked upload: the TUS protocol (tus.io) or the cloud provider's resumable upload |

For presigned uploads, `POST /v1/uploads` with `{"filename", "content_type"}` returns an `upload_url`, `expires_in`, and a `resource_id`; the client then `PUT`s the bytes to `upload_url`, bypassing the API server.
