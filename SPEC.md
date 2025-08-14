# GURT Protocol Specification

GURT is a TCP-based application protocol designed as an HTTP-like alternative with built-in TLS 1.3 encryption.

### Quick Info

- **HTTP-like syntax** with familiar methods (GET, POST, PUT, DELETE, etc.)
- **Built-in required TLS 1.3 encryption** for secure communication
- **Binary and text data support**
- **Status codes** compatible with HTTP semantics
- **Default port**: 4878

### Version

Current version: **GURT/1.0.0**

---

## Communication

- **All connections must start with a HANDSHAKE request.**
- After handshake, all further messages are sent over the encrypted TLS 1.3 connection.

### Message Types

1. **HANDSHAKE** - Establishes encrypted connection (method: `HANDSHAKE`)
2. **Standard Requests** - `GET`, `POST`, `PUT`, `DELETE`, `HEAD`, `OPTIONS`, `PATCH`
3. **Responses** - Status code with optional body

---

## Message Format

### Request Format

```
METHOD /path GURT/1.0.0\r\n
header-name: header-value\r\n
content-length: 123\r\n
user-agent: GURT-Client/1.0.0\r\n
\r\n
[message body]
```

- **METHOD**: One of `GET`, `POST`, `PUT`, `DELETE`, `HEAD`, `OPTIONS`, `PATCH`, `HANDSHAKE`
- **Headers**: Lowercase, separated by `:`, terminated by `\r\n`
- **Header separator**: `\r\n`
- **Body separator**: `\r\n\r\n`
- **Content-Length**: Required for all requests with a body
- **User-Agent**: Sent by default by the Rust client

### Response Format

```
GURT/1.0.0 200 OK\r\n
header-name: header-value\r\n
content-length: 123\r\n
server: GURT/1.0.0\r\n
date: Wed, 01 Jan 2020 00:00:00 GMT\r\n
\r\n
[message body]
```

- **Status line**: `GURT/1.0.0 <status_code> <status_message>`
- **Headers**: Lowercase, separated by `:`, terminated by `\r\n`
- **Header separator**: `\r\n`
- **Body separator**: `\r\n\r\n`
- **Content-Length**: Required for all responses with a body
- **Server**: Sent by default by the Rust server
- **Date**: RFC 7231 format, sent by default

### Header Notes

- All header names are **lowercased** in the protocol implementation.
- Unknown headers are ignored by default.
- Header order is not significant.

### Status Codes

- **1xx Informational**
  - `101` - Switching Protocols (handshake success)

- **2xx Success**
  - `200` - OK
  - `201` - Created
  - `202` - Accepted
  - `204` - No Content

- **4xx Client Error**
  - `400` - Bad Request
  - `401` - Unauthorized
  - `403` - Forbidden
  - `404` - Not Found
  - `405` - Method Not Allowed
  - `408` - Timeout
  - `413` - Too Large

- **5xx Server Error**
  - `500` - Internal Server Error
  - `501` - Not Implemented
  - `502` - Bad Gateway
  - `503` - Service Unavailable
  - `504` - Gateway Timeout

---

## Security

### TLS 1.3 Handshake

- **All connections must use TLS 1.3**.
- **ALPN**: `"GURT/1.0"` (see `GURT_ALPN` in code)
- **Handshake**: The first message must be a `HANDSHAKE` request.
- **Server responds** with `101 Switching Protocols` and headers:
  - `gurt-version: 1.0.0`
  - `encryption: TLS/1.3`
  - `alpn: GURT/1.0`

---

## Example Request

Below is a full example of the TCP communication for a GURT session, including handshake and a POST request/response.

```py
# Client
HANDSHAKE / GURT/1.0.0\r\n
host: example.com\r\n
user-agent: GURT-Client/1.0.0\r\n
\r\n

# Server
GURT/1.0.0 101 SWITCHING_PROTOCOLS\r\n
gurt-version: 1.0.0\r\n
encryption: TLS/1.3\r\n
alpn: gurt/1.0\r\n
server: GURT/1.0.0\r\n
date: Wed, 01 Jan 2020 00:00:00 GMT\r\n
\r\n

# Handshake is now complete; all further messages are encrypted ---

# Client
POST /api/data GURT/1.0.0\r\n
host: example.com\r\n
content-type: application/json\r\n
content-length: 17\r\n
user-agent: GURT-Client/1.0.0\r\n
\r\n
{"foo":"bar","x":1}

# Server
GURT/1.0.0 200 OK\r\n
content-type: application/json\r\n
content-length: 16\r\n
server: GURT/1.0.0\r\n
date: Wed, 01 Jan 2020 00:00:00 GMT\r\n
\r\n
{"result":"ok"}
```

## Testing

```bash
cargo test -- --nocapture
```

## Get Started
Check the `cli` folder for **Gurty**, a CLI tool to set up your GURT server.