# OpenResty PHP Development Guide

## Project Overview
This is a containerized OpenResty web server optimized for Laravel PHP applications with automatic SSL certificate management. The setup combines OpenResty (Nginx + LuaJIT) with lua-resty-auto-ssl for dynamic SSL certificate provisioning.

## Architecture

### Core Components
- **OpenResty**: Alpine-based container with Nginx + Lua runtime
- **Auto-SSL**: Automatic Let's Encrypt certificate management via lua-resty-auto-ssl
- **PHP-FPM Integration**: Ready for FastCGI PHP processing (requires external PHP container)

### Key Files & Structure
- `Dockerfile`: Multi-stage build with SSL setup and www-data user configuration
- `docker-compose.yml`: Service definition exposing port 33333 with volume mounts
- `example/conf/nginx.conf`: Main nginx configuration with auto-ssl initialization
- `example/conf.d/server.conf`: Virtual host configuration with SSL termination and Laravel routing

## Development Patterns

### SSL Certificate Management
The project uses lua-resty-auto-ssl for automatic certificate provisioning:
- Fallback certificates are generated during build (`/etc/resty-auto-ssl/fallback.{crt,key}`)
- Domain validation occurs in `init_by_lua_block` via the `allow_domain` function
- Internal server on port 8999 handles ACME challenges

### Nginx Configuration Patterns
- **Modern HTTP/2**: Uses `http2 on;` directive (nginx 1.25.1+)
- **Force WWW redirect**: Configurable non-www to www redirect (respects localhost/development)
- **HTTPS enforcement**: All HTTP traffic redirects to HTTPS
- **Laravel routing**: `try_files $uri $uri/ /index.php?$query_string` pattern
- **Static asset optimization**: Modern caching with immutable headers for versioned assets
- **Security headers**: HSTS, X-Frame-Options, CSP-ready configuration
- **Modern SSL**: TLS 1.2/1.3 with secure cipher suites

### Docker Development Workflow
```bash
# Setup environment
./setup.sh

# Configure domains and SSL in .env file
ALLOWED_DOMAINS=your-domain.com,*.your-domain.com
SSL_EMAIL=your-email@domain.com

# Build and run the container
docker-compose up --build

# Access the server
curl http://localhost:33333   # HTTP (redirects to HTTPS)
curl https://localhost:33334  # HTTPS
```

## File Modification Guidelines

### Adding New Domains
Configure domains via environment variables in `.env` file:
```bash
# Single domain
ALLOWED_DOMAINS=example.com,www.example.com

# Wildcard domains
ALLOWED_DOMAINS=*.example.com,example.com

# Multiple domains
ALLOWED_DOMAINS=domain1.com,*.domain1.com,domain2.com,*.domain2.com

# Development (default)
ALLOWED_DOMAINS=localhost,*.local,127.0.0.1
```

### SSL Configuration
Set up SSL via environment variables:
```bash
# Production SSL
SSL_EMAIL=admin@example.com
SSL_STAGING=false

# Testing SSL (avoids rate limits)
SSL_EMAIL=admin@example.com
SSL_STAGING=true
```

### PHP Integration
The FastCGI configuration in `server.conf` is ready for PHP-FPM:
- Uncomment `fastcgi_pass php:9000;` when adding PHP service
- Document root is set to `/var/www/html/public` (Laravel convention)

### Configuration Updates
- Main nginx config: Modify `example/conf/nginx.conf`
- Virtual hosts: Add files to `example/conf.d/`
- Volume mounts in `docker-compose.yml` automatically sync changes

## Security Considerations
- www-data user (UID 82) for nginx processes
- SSL certificates stored in `/etc/resty-auto-ssl/`
- Proper file permissions set during build
- Resolver set to 8.8.8.8 for DNS resolution

## Debugging
- Error logs: `/usr/local/openresty/nginx/logs/error-*.log`
- Access logs: `/usr/local/openresty/nginx/logs/access-*.log`
- Check certificate generation in auto-ssl shared dict