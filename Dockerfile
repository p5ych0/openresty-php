# Build stage for compiling lua-resty-auto-ssl and setting up SSL certificates
FROM openresty/openresty:alpine-fat AS builder

# Install build dependencies and install lua-resty-auto-ssl
RUN apk add --no-cache --virtual .build-deps \
        gcc \
        libc-dev \
        make \
        openssl \
        openssl-dev \
        pcre-dev \
        zlib-dev \
        linux-headers \
        gnupg \
        libxslt-dev \
        gd-dev \
        geoip-dev \
        perl-dev \
        tar \
        unzip \
        zip \
        g++ \
        cmake \
        lua \
        lua-dev \
        autoconf \
        automake \
    && PATH=$PATH:/usr/bin /usr/local/openresty/luajit/bin/luarocks install shell-games \
    && PATH=$PATH:/usr/bin /usr/local/openresty/luajit/bin/luarocks install lua-resty-auto-ssl \
    && mkdir -p /etc/resty-auto-ssl \
    && mkdir -p /usr/local/openresty/luajit/bin/resty-auto-ssl \
    && openssl req -new -newkey rsa:4096 -days 365 -nodes -sha256 -x509 \
       -keyout /etc/resty-auto-ssl/fallback.key \
       -out /etc/resty-auto-ssl/fallback.crt \
       -subj '/CN=localhost-sni-support-required-for-valid-ssl' \
       -extensions EXT -config <( \
         printf "[dn]\nCN=localhost\n[req]\ndistinguished_name = dn\n[EXT]\nsubjectAltName=DNS:localhost\nkeyUsage=digitalSignature\nextendedKeyUsage=serverAuth") \
    && apk del .build-deps \
    && rm -rf /var/cache/apk/*

# Production stage
FROM openresty/openresty:alpine-fat

# Labels for metadata
LABEL maintainer="OpenResty PHP Project" \
      version="2.0" \
      description="Modern OpenResty server for Laravel with auto-SSL" \
      org.opencontainers.image.source="https://github.com/p5ych0/openresty-php"

# Install runtime dependencies
RUN apk add --no-cache \
    bash \
    curl \
    diffutils \
    grep \
    sed \
    openssl \
    mc \
    wget \
    libcap \
    shadow \
    net-tools \
    nss-tools \
    procps \
    su-exec \
    && rm -rf /var/cache/apk/*

# Copy lua-resty-auto-ssl and all dependencies from builder stage
COPY --from=builder /usr/local/openresty/luajit/share/lua /usr/local/openresty/luajit/share/lua
COPY --from=builder /usr/local/openresty/luajit/lib/luarocks /usr/local/openresty/luajit/lib/luarocks
COPY --from=builder /usr/local/openresty/luajit/bin /usr/local/openresty/luajit/bin

# Copy SSL certificates from builder
COPY --from=builder /etc/resty-auto-ssl /etc/resty-auto-ssl

# Create necessary directories with proper OpenResty structure
RUN mkdir -p /var/cache/nginx \
             /usr/local/openresty/nginx/logs \
             /usr/local/openresty/nginx/conf.d \
             /usr/local/openresty/nginx/client_body_temp \
             /usr/local/openresty/nginx/proxy_temp \
             /usr/local/openresty/nginx/fastcgi_temp \
             /usr/local/openresty/nginx/uwsgi_temp \
             /usr/local/openresty/nginx/scgi_temp \
             /var/www/html/public \
    && rm -rf /etc/nginx/conf.d \
              /usr/local/openresty/nginx/conf

# Create entrypoint script for dynamic user management
COPY <<'EOF' /docker-entrypoint.sh
#!/bin/bash
set -e

# Default values
USER_ID=${PUID:-82}
GROUP_ID=${PGID:-82}
USER_NAME=${USER_NAME:-www-data}
GROUP_NAME=${GROUP_NAME:-www-data}

# Create group if it doesn't exist
if ! getent group "$GROUP_NAME" > /dev/null 2>&1; then
    addgroup -g "$GROUP_ID" "$GROUP_NAME"
else
    # Update group ID if different
    current_gid=$(getent group "$GROUP_NAME" | cut -d: -f3)
    if [ "$current_gid" != "$GROUP_ID" ]; then
        delgroup "$GROUP_NAME" 2>/dev/null || true
        addgroup -g "$GROUP_ID" "$GROUP_NAME"
    fi
fi

# Create user if it doesn't exist
if ! getent passwd "$USER_NAME" > /dev/null 2>&1; then
    adduser -u "$USER_ID" -D -S -h /var/cache/nginx -s /sbin/nologin -G "$GROUP_NAME" "$USER_NAME"
else
    # Update user ID if different
    current_uid=$(getent passwd "$USER_NAME" | cut -d: -f3)
    if [ "$current_uid" != "$USER_ID" ]; then
        deluser "$USER_NAME" 2>/dev/null || true
        adduser -u "$USER_ID" -D -S -h /var/cache/nginx -s /sbin/nologin -G "$GROUP_NAME" "$USER_NAME"
    fi
fi

# Set ownership of critical directories (skip read-only mounted volumes)
chown -R "$USER_NAME:$GROUP_NAME" \
    /etc/resty-auto-ssl \
    /usr/local/openresty/nginx \
    /var/cache/nginx \
    /var/www/html 2>/dev/null || true

# Set proper permissions (skip read-only mounted directories)
chmod 0775 /usr/local/openresty/nginx/logs /var/cache/nginx 2>/dev/null || true
chmod 0775 /usr/local/openresty/nginx/cache /var/cache/nginx 2>/dev/null || true
chmod 0775 /usr/local/openresty/nginx/*_temp 2>/dev/null || true
chmod 0755 /etc/resty-auto-ssl 2>/dev/null || true

# Update nginx configuration to use the correct user (only if writable)
if [ -f /usr/local/openresty/nginx/conf/nginx.conf ] && [ -w /usr/local/openresty/nginx/conf/nginx.conf ]; then
    sed -i "s/^user .*/user $USER_NAME;/" /usr/local/openresty/nginx/conf/nginx.conf
elif [ -f /usr/local/openresty/nginx/conf/nginx.conf ]; then
    echo "Note: nginx.conf is read-only, user directive cannot be updated dynamically"
fi

echo "Starting OpenResty as $USER_NAME (UID: $USER_ID, GID: $GROUP_ID)"

# Execute the command with the specified user
exec su-exec "$USER_NAME" "$@"
EOF

# Make entrypoint executable
RUN chmod +x /docker-entrypoint.sh

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD curl -f http://localhost/ || exit 1

# Security: Run as non-root by default (can be overridden)
ENV PUID=82 \
    PGID=82 \
    USER_NAME=www-data \
    GROUP_NAME=www-data

# Expose ports
EXPOSE 80 443

WORKDIR /var/www/html/public

ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["/usr/local/openresty/bin/openresty", "-g", "daemon off;"]
