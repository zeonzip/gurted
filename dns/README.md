# Domain Management API

This is a Domain Management API built with Rust (Actix Web) and PostgreSQL. It provides user authentication, domain registration with Discord approval workflow, and invite-based registration limits.

## Features

- 🔐 **JWT Authentication** - Secure user registration and login
- 📝 **Domain Registration** - Submit domains for approval with usage limits
- 🤖 **Discord Integration** - Automatic approval workflow via Discord bot
- 📧 **Invite System** - Users can share registration slots via invite codes
- 🛡️ **Rate Limiting** - Protection against abuse
- 📊 **PostgreSQL Database** - Reliable data storage with migrations

## Table of Contents

- [Authentication Endpoints](#authentication-endpoints)
  - [POST /auth/register](#post-authregister)
  - [POST /auth/login](#post-authlogin)
  - [GET /auth/me](#get-authme)
  - [POST /auth/invite](#post-authinvite)
  - [POST /auth/redeem-invite](#post-authredeem-invite)
- [Domain Endpoints](#domain-endpoints)
  - [GET /](#get-)
  - [POST /domain](#post-domain) 🔒
  - [GET /domain/:name/:tld](#get-domainnametld)
  - [PUT /domain/:name/:tld](#put-domainnametld) 🔒
  - [DELETE /domain/:name/:tld](#delete-domainnametld) 🔒
  - [GET /domains](#get-domains)
  - [GET /tlds](#get-tlds)
  - [POST /domain/check](#post-domaincheck)

🔒 = Requires authentication

## Authentication Endpoints

### POST /auth/register

Register a new user account. New users start with 3 domain registrations.

**Request:**
```json
{
  "username": "myusername",
  "password": "mypassword"
}
```

**Response:**
```json
{
  "token": "jwt-token-here",
  "user": {
    "id": 1,
    "username": "myusername",
    "registrations_remaining": 3,
    "created_at": "2023-01-01T00:00:00Z"
  }
}
```

### POST /auth/login

Login with existing credentials.

**Request:**
```json
{
  "username": "myusername",
  "password": "mypassword"
}
```

**Response:**
```json
{
  "token": "jwt-token-here",
  "user": {
    "id": 1,
    "username": "myusername",
    "registrations_remaining": 2,
    "created_at": "2023-01-01T00:00:00Z"
  }
}
```

### GET /auth/me 🔒

Get current user information. Requires `Authorization: Bearer <token>` header.

**Response:**
```json
{
  "id": 1,
  "username": "myusername",
  "registrations_remaining": 2,
  "created_at": "2023-01-01T00:00:00Z"
}
```

### POST /auth/invite 🔒

Create an invite code that can be redeemed for 3 additional domain registrations. Requires authentication but does NOT consume any of your registrations.

**Response:**
```json
{
  "invite_code": "abc123def456"
}
```

### POST /auth/redeem-invite 🔒

Redeem an invite code to get 3 additional domain registrations. Requires authentication.

**Request:**
```json
{
  "invite_code": "abc123def456"
}
```

**Response:**
```json
{
  "message": "Invite code redeemed successfully",
  "registrations_added": 3
}
```

## Domain Endpoints

### GET /

Returns a simple message with the available endpoints and rate limits.

**Response:**

```
Hello, world! The available endpoints are:
GET /domains,
GET /domain/{name}/{tld},
POST /domain,
PUT /domain/{key},
DELETE /domain/{key},
GET /tlds.
Ratelimits are as follows: 10 requests per 60s.
```

### POST /domain 🔒

Submit a domain for approval. Requires authentication and consumes one registration slot. The domain will be sent to Discord for manual approval.

**Request:**
```json
{
  "tld": "dev",
  "ip": "192.168.1.100",
  "name": "myawesome"
}
```

**Response:**
```json
{
  "message": "Domain registration submitted for approval",
  "domain": "myawesome.dev",
  "status": "pending"
}
```

**Error Responses:**
- `401 Unauthorized` - Missing or invalid JWT token
- `400 Bad Request` - No registrations remaining, invalid domain, or offensive name
- `409 Conflict` - Domain already exists

### GET /domain/:name/:tld

Fetch an approved domain by name and TLD. Only returns domains with 'approved' status.

**Response:**
```json
{
  "tld": "dev",
  "name": "myawesome",
  "ip": "192.168.1.100"
}
```

### PUT /domain/:name/:tld 🔒

Update the IP address of your approved domain. You can only update domains you own.

**Request:**
```json
{
  "ip": "10.0.0.50"
}
```

**Response:**
```json
{
  "ip": "10.0.0.50"
}
```

### DELETE /domain/:name/:tld 🔒

Delete your domain. You can only delete domains you own.

**Response:**
- `200 OK` - Domain deleted successfully
- `404 Not Found` - Domain not found or not owned by you

### GET /domains

Fetch all approved domains with pagination support. Only shows domains with 'approved' status.

**Query Parameters:**
- `page` (or `p`) - Page number (default: 1)
- `page_size` (or `s`, `size`, `l`, `limit`) - Items per page (default: 15, max: 100)

**Response:**
```json
{
  "domains": [
    {
      "tld": "dev",
      "name": "myawesome",
      "ip": "192.168.1.100"
    }
  ],
  "page": 1,
  "limit": 15
}
```

### GET /tlds

Get the list of allowed top-level domains.

**Response:**
```json
["mf", "btw", "fr", "yap", "dev", "scam", "zip", "root", "web", "rizz", "habibi", "sigma", "now", "it", "soy", "lol", "uwu", "ohio", "cat"]
```

### POST /domain/check

Check if domain name(s) are available.

**Request:**
```json
{
  "name": "myawesome",
  "tld": "dev"  // Optional - if omitted, checks all TLDs
}
```

**Response:**
```json
[
  {
    "domain": "myawesome.dev",
    "taken": false
  }
]
```

## Discord Integration

When a user submits a domain registration, it's automatically sent to a configured Discord channel with:

- 📝 Domain details (name, TLD, IP, user info)
- ✅ **Approve** button - Marks domain as approved
- ❌ **Deny** button - Opens modal asking for denial reason

Discord admins can approve or deny registrations directly from Discord.

## Configuration

Copy `config.template.toml` to `config.toml` and configure your settings.

## Rate Limits

- **Domain Registration**: 5 requests per 10 minutes (per IP)
- **General API**: No specific limits (yet)

## Domain Registration Limits

- **User Limit**: Each user has a finite number of domain registrations
- **Usage**: Each domain submission consumes 1 registration from your account
- **Replenishment**: Use invite codes to get more registrations (3 per invite)

## User Registration & Invites

- **Registration**: Anyone can register - no invite required
- **New Users**: Start with 3 domain registrations automatically
- **Invite Creation**: Any authenticated user can create invite codes (no cost)
- **Invite Redemption**: Redeem invite codes for 3 additional domain registrations
- **Invite Usage**: Each invite code can only be redeemed once
