# Wasambazie SMS API

REST API for programmatic SMS sending. All requests and responses use JSON.

- **Base URL:** `https://wasambazie.co.tz/v1`
- **Transport:** HTTPS only
- **Auth scheme:** API Key (recommended for SMS/webhook/balance operations)

---

## Authentication

Every request requires two headers:

| Header | Format | Notes |
|---|---|---|
| `X-API-PUBLIC-KEY` | `pk__d-H9yWJvInRJ3rwPsKOsaSKG3ZSyhSG0DEK3UhiKZU` | Always prefixed with `pk_` |
| `X-API-SECRET-KEY` | `sk_wKZ4XR03-Bh_qwxodQvOj0mxTcmVKnohQPUV3G3_NzA` | Always prefixed with `sk_`. **Shown once at generation — store immediately.** Cannot be retrieved, only regenerated. |

Obtain keys from: **Settings → API Keys → Generate New Key Pair**

- Never expose keys in client-side code (browsers, mobile apps)
- Keys can be revoked at any time from the portal
- Missing or invalid keys → `401 Unauthorized`

```json
{ "detail": "Invalid or missing API credentials" }
```

---

## Endpoints

### Send SMS

```
POST /sms/send
```

**Headers:**
```
Content-Type:      application/json
X-API-PUBLIC-KEY:  pk__d-H9yWJvInRJ3rwPsKOsaSKG3ZSyhSG0DEK3UhiKZU
X-API-SECRET-KEY:  sk_wKZ4XR03-Bh_qwxodQvOj0mxTcmVKnohQPUV3G3_NzA
```

**Request Body:**

| Field | Type | Required | Description |
|---|---|---|---|
| `to_number` | string | ✅ | Single number or comma-separated list. International format: `+255XXXXXXXXX` |
| `message` | string | ✅ | Plain text SMS content |
| `sender_id` | string | ✅ | Approved sender name (e.g. `MYBRAND`). Must be pre-approved. |

**Success — `201 Created`:**
```json
{
  "status_code":      201,
  "success":          true,
  "message_batch_id": "abc123xyz",
  "message":          "Message submitted successfully."
}
```

> **Save `message_batch_id`** — needed for polling delivery reports and matching webhook payloads.

**Error Responses:**

| Status | Body |
|---|---|
| `400` | `{ "detail": "Sender ID is required" }` |
| `402` | `{ "detail": "Insufficient SMS credits" }` |
| `404` | `{ "detail": "Sender ID not found or not approved" }` |
| `502` | `{ "detail": "Provider rejected the message" }` — no credits deducted |

> Credits are deducted **after** the provider accepts the message. A `502` means no charge.

---

### Check Balance

```
GET /balance/
```

**Headers:**
```
X-API-PUBLIC-KEY:  pk__d-H9yWJvInRJ3rwPsKOsaSKG3ZSyhSG0DEK3UhiKZU
X-API-SECRET-KEY:  sk_wKZ4XR03-Bh_qwxodQvOj0mxTcmVKnohQPUV3G3_NzA
```

**Response — `200 OK`:**
```json
{ "balance": 4250.0 }
```

Balance is a **credit count** (not monetary). 1 credit = 1 SMS segment to 1 recipient.

> Check balance before bulk sends to avoid partial delivery.

---

### Delivery Reports (Polling)

```
GET /sms/delivery-reports/{batch_id}
```

**Response — `200 OK`:**
```json
{
  "message_batch_id": "abc123xyz",
  "summary": {
    "total":     3,
    "delivered": 2,
    "failed":    1
  },
  "messages": [
    {
      "to_number":    "+255712345678",
      "status":       "delivered",
      "delivered_at": "2024-01-15T10:30:00Z"
    }
  ]
}
```

**Not yet available — `404`:**
```json
{ "detail": "Report not yet available — the batch is still being processed." }
```

**Polling guidance:**
- Wait at least **30 seconds** before first poll
- Use exponential backoff: `30s → 60s → 120s → 240s`
- For high volume, prefer Webhooks over polling

---

## Sender IDs

The name shown to recipients instead of a phone number (e.g. `MYBRAND`).

**Rules:**
- Max 11 characters
- Letters and numbers only — no spaces, no symbols
- All uppercase (API normalises automatically)
- Must be **approved before use**

**Request approval:** Settings → Sender IDs in the portal (takes 1–2 weeks)

| Status | Meaning |
|---|---|
| `pending` | Submitted, awaiting review |
| `approved` | Active — usable in `POST /sms/send` |
| `rejected` | Not approved. Submit a new request with a different name |

**Usage in API:**
```json
"sender_id": "HAFLAWAY"
```

---

## Webhooks

Wasambazie POSTs delivery data to your server automatically when a batch finalises — no polling needed.

**Setup (portal only, no API needed):**
1. Settings → Webhooks → Add Webhook
2. Enter your endpoint URL
3. Copy the webhook secret (shown **once only**)
4. Webhook is active immediately

From the portal: view webhooks, enable/disable, inspect delivery history, manually retry failures.

**Incoming Payload:**
```json
{
  "event":            "delivery.batch.finalized",
  "message_batch_id": "abc123xyz",
  "summary": {
    "total":     3,
    "delivered": 2,
    "failed":    1
  },
  "messages": [
    {
      "to_number":    "+255712345678",
      "status":       "delivered",
      "delivered_at": "2024-01-15T10:30:00Z"
    }
  ]
}
```

**Your endpoint must:**
- Respond `HTTP 200` within a reasonable timeout
- Any non-200 or timeout → treated as failure → retried up to **5 times** with exponential backoff

### Signature Verification (Recommended)

Verify the `X-Wasambazie-Signature` header to confirm requests are genuine.

1. Read the **raw request body** (before JSON parsing)
2. Compute `HMAC-SHA256` of the raw body using your webhook secret as the key
3. Compare hex-encoded result with `X-Wasambazie-Signature`
4. Mismatch → reject with `400`

```python
import hmac, hashlib

def verify(secret: str, payload: bytes, signature: str) -> bool:
    expected = hmac.new(secret.encode(), payload, hashlib.sha256).hexdigest()
    return hmac.compare_digest(expected, signature)
```

---

## Message Status Values

Use **case-insensitive** comparison in your code.

| Status | Description |
|---|---|
| `queued` | Accepted by gateway, waiting to be sent to provider |
| `sent` | Handed to the SMS provider |
| `delivered` | Provider confirmed delivery to handset |
| `failed` | Delivery failed — provider error or timeout |

---

## Segmentation & Billing

Credits formula:
```
credits_used = num_segments(message) × num_recipients
```

| Encoding | Single message | Multi-part (per segment) |
|---|---|---|
| GSM-7 (standard Latin) | 160 chars | 153 chars |
| Unicode (Arabic, Chinese, emoji, etc.) | 70 chars | 67 chars |

**Examples:**

| Message length | Segments | Recipients | Credits used |
|---|---|---|---|
| 120 chars | 1 | 100 | 100 |
| 180 chars | 2 | 50 | 100 |

---

## Error Reference

All errors return:
```json
{ "detail": "Human-readable error message" }
```

| Status | Meaning |
|---|---|
| `200` | OK |
| `201` | Created |
| `204` | No Content (deletion succeeded) |
| `400` | Bad Request — missing or invalid fields |
| `401` | Unauthorized — missing, invalid, or revoked API keys |
| `402` | Payment Required — insufficient SMS credits |
| `403` | Forbidden — no permission for this resource |
| `404` | Not Found — resource doesn't exist or doesn't belong to your account |
| `409` | Conflict — duplicate entry (e.g. phone number already registered) |
| `422` | Unprocessable Entity — field-level validation errors (see below) |
| `500` | Internal Server Error — retry the request |
| `502` | Bad Gateway — upstream provider error, **no credits deducted** |

**422 Validation Error Format:**
```json
{
  "detail": [
    {
      "loc":  ["body", "to_number"],
      "msg":  "field required",
      "type": "value_error.missing"
    }
  ]
}
```

---

## Code Examples

### cURL

```bash
# Check balance
curl -X GET 'https://wasambazie.co.tz/v1/balance/' \
  -H 'X-API-PUBLIC-KEY: pk__d-H9yWJvInRJ3rwPsKOsaSKG3ZSyhSG0DEK3UhiKZU' \
  -H 'X-API-SECRET-KEY: sk_wKZ4XR03-Bh_qwxodQvOj0mxTcmVKnohQPUV3G3_NzA'

# Send a single SMS
curl -X POST 'https://wasambazie.co.tz/v1/sms/send' \
  -H 'Content-Type: application/json' \
  -H 'X-API-PUBLIC-KEY: pk__d-H9yWJvInRJ3rwPsKOsaSKG3ZSyhSG0DEK3UhiKZU' \
  -H 'X-API-SECRET-KEY: sk_wKZ4XR03-Bh_qwxodQvOj0mxTcmVKnohQPUV3G3_NzA' \
  -d '{
    "to_number":  "+255712345678",
    "message":    "Hello from Wasambazie!",
    "sender_id":  "HAFLAWAY"
  }'

# Send to multiple recipients (comma-separated)
curl -X POST 'https://wasambazie.co.tz/v1/sms/send' \
  -H 'Content-Type: application/json' \
  -H 'X-API-PUBLIC-KEY: pk__d-H9yWJvInRJ3rwPsKOsaSKG3ZSyhSG0DEK3UhiKZU' \
  -H 'X-API-SECRET-KEY: sk_wKZ4XR03-Bh_qwxodQvOj0mxTcmVKnohQPUV3G3_NzA' \
  -d '{
    "to_number":  "+255712345678,+255722345678,+255732345679",
    "message":    "Your order has been confirmed.",
    "sender_id":  "HAFLAWAY"
  }'

# Poll delivery report
curl -X GET 'https://wasambazie.co.tz/v1/sms/delivery-reports/abc123xyz' \
  -H 'X-API-PUBLIC-KEY: pk__d-H9yWJvInRJ3rwPsKOsaSKG3ZSyhSG0DEK3UhiKZU' \
  -H 'X-API-SECRET-KEY: sk_wKZ4XR03-Bh_qwxodQvOj0mxTcmVKnohQPUV3G3_NzA'
```

---

## Quick Reference

| Task | Method | Path |
|---|---|---|
| Send SMS | `POST` | `/sms/send` |
| Check balance | `GET` | `/balance/` |
| Poll delivery report | `GET` | `/sms/delivery-reports/{batch_id}` |
