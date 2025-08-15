---
sidebar_position: 5
---

# Gurty CLI Tool

**Gurty** is a command-line interface tool for setting up and managing GURT protocol servers. It provides an easy way to deploy GURT servers with proper TLS configuration for both development and production environments.

## Installation

Build Gurty from the protocol CLI directory:

```bash
cd protocol/cli
cargo build --release
```

The binary will be available at `target/release/gurty` (or `gurty.exe` on Windows).

## Quick Start

### Development Setup

1. **Install mkcert** for development certificates:
   ```bash
   # Windows (with Chocolatey)
   choco install mkcert
   
   # macOS (with Homebrew)
   brew install mkcert
   
   # Or download from: https://github.com/FiloSottile/mkcert/releases
   ```

2. **Install local CA** in your system:
   ```bash
   mkcert -install
   ```

3. **Generate localhost certificates**:
   ```bash
   cd protocol/cli
   mkcert localhost 127.0.0.1 ::1
   ```
   This creates:
   - `localhost+2.pem` (certificate)
   - `localhost+2-key.pem` (private key)

4. **Start GURT server**:
   ```bash
   cargo run --release serve --cert localhost+2.pem --key localhost+2-key.pem
   ```

### Production Setup

1. **Generate production certificates** with OpenSSL:
   ```bash
   # Generate private key
   openssl genpkey -algorithm RSA -out gurt-server.key -pkcs8
   
   # Generate certificate signing request
   openssl req -new -key gurt-server.key -out gurt-server.csr
   
   # Generate self-signed certificate (valid for 365 days)
   openssl x509 -req -days 365 -in gurt-server.csr -signkey gurt-server.key -out gurt-server.crt
   
   # Or generate both in one step
   openssl req -x509 -newkey rsa:4096 -keyout gurt-server.key -out gurt-server.crt -days 365 -nodes
   ```

2. **Deploy with production certificates**:
   ```bash
   cargo run --release serve --cert gurt-server.crt --key gurt-server.key --host 0.0.0.0 --port 4878
   ```

## Commands

### `serve` Command

Start a GURT server with TLS certificates.

```bash
gurty serve [OPTIONS]
```

#### Options

| Option | Description | Default |
|--------|-------------|---------|
| `--cert <FILE>` | Path to TLS certificate file | Required |
| `--key <FILE>` | Path to TLS private key file | Required |
| `--host <HOST>` | Host address to bind to | `127.0.0.1` |
| `--port <PORT>` | Port number to listen on | `4878` |
| `--dir <DIR>` | Directory to serve files from | None |
| `--log-level <LEVEL>` | Logging level (error, warn, info, debug, trace) | `info` |

#### Examples

```bash
gurty serve --cert localhost+2.pem --key localhost+2-key.pem --dir ./public
```
Debug:
```bash
gurty serve --cert dev.pem --key dev-key.pem --log-level debug
```
