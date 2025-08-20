# Gurty - a CLI tool to setup your GURT Protocol server

Gurty is a command-line interface tool for setting up and managing GURT protocol servers.

## Configuration

Gurty uses a TOML configuration file to manage server settings. The `gurty.template.toml` file provides a complete configuration template with all available options:

### Sections

- **Server**: Basic server settings (host, port, protocol version, connection limits)
- **TLS**: Certificate and private key configuration for secure connections
- **Logging**: Logging levels, request/response logging, and log file paths
- **Security**: File access restrictions, allowed HTTP methods, and rate limiting
- **Error Pages**: Custom error page templates and default error responses
- **Headers**: Custom HTTP headers for security and server identification

### Using Configuration Files

1. **Copy the configuration template:**
   ```bash
   cp gurty.template.toml gurty.toml
   ```

2. **Edit the configuration** to match your environment. (optional)

3. **Use the configuration file:**
   ```bash
   gurty serve --config gurty.toml
   ```

## Setup for Production

For production deployments, you'll need to generate your own certificates since traditional Certificate Authorities don't support custom protocols:

1. **Generate production certificates with OpenSSL:**
   ```bash
   # Generate private key
   openssl genpkey -algorithm RSA -out gurt-server.key -pkcs8 -v

   # Generate certificate signing request
   openssl req -new -key gurt-server.key -out gurt-server.csr

   # Generate self-signed certificate (valid for 365 days)
   openssl x509 -req -days 365 -in gurt-server.csr -signkey gurt-server.key -out gurt-server.crt

   # Or generate both key and certificate in one step
   openssl req -x509 -newkey rsa:4096 -keyout gurt-server.key -out gurt-server.crt -days 365 -nodes
   ```

2. **Copy the configuration template and customize:**
   ```bash
   cp gurty.template.toml gurty.toml
   ```

3. **Deploy with production certificates and configuration:**
   ```bash
   gurty serve --config gurty.toml
   ```
   Or specify certificates explicitly:
   ```bash
   gurty serve --cert gurt-server.crt --key gurt-server.key --config gurty.toml
   ```

## Development Environment Setup

To set up a development environment for GURT, follow these steps:

1. **Install mkcert:**
   ```bash
   # Windows (with Chocolatey)
   choco install mkcert
   
   # Or download from: https://github.com/FiloSottile/mkcert/releases
   ```

2. **Install local CA in system:**
   ```bash
   mkcert -install
   ```
   This installs a local CA in your **system certificate store**.

3. **Generate localhost certificates:**
   ```bash
   cd gurted/protocol/cli
   mkcert localhost 127.0.0.1 ::1
   ```
   This creates:
   - `localhost+2.pem` (certificate)
   - `localhost+2-key.pem` (private key)

4. **Copy the configuration template and customize:**
   ```bash
   cp gurty.template.toml gurty.toml
   ```

5. **Start GURT server with certificates and configuration:**
   ```bash
   gurty serve --config gurty.toml
   ```
   Or specify certificates explicitly:
   ```bash
   gurty serve --cert localhost+2.pem --key localhost+2-key.pem --config gurty.toml
   ```