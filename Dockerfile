FROM openresty/openresty:alpine-fat

RUN apk add --no-cache --virtual .run-deps \
    bash \
    curl \
    diffutils \
    grep \
    sed \
    openssl \
    mc \
    wget \
    net-tools \
    nss-tools \
    procps \
    && mkdir -p /etc/resty-auto-ssl \
    && adduser -u 82 -D -S -h /var/cache/nginx -s /sbin/nologin -G www-data www-data

RUN ["/bin/bash", "-c", "openssl req -new -newkey rsa:2048 -days 365 -nodes -sha256 -x509 \
      -keyout /etc/resty-auto-ssl/fallback.key \
      -out /etc/resty-auto-ssl/fallback.crt \
      -subj '/CN=localhost-sni-support-required-for-valid-ssl' -extensions EXT -config <( \
       printf \"[dn]\nCN=localhost\n[req]\ndistinguished_name = dn\n[EXT]\nsubjectAltName=DNS:localhost\nkeyUsage=digitalSignature\nextendedKeyUsage=serverAuth\")"]

RUN chown www-data -R /etc/resty-auto-ssl \
    && chown www-data /etc/resty-auto-ssl \
    && mkdir /var/log/nginx \
    && chown www-data:www-data /var/log/nginx \
    && chmod 0775 /var/log/nginx

RUN apk add --no-cache --virtual .build-deps \
        gcc \
        libc-dev \
        make \
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
    && /usr/local/openresty/luajit/bin/luarocks install lua-resty-auto-ssl \
    && apk del .build-deps \
    && mkdir -p /var/cache/nginx \
    && rm -rf /etc/nginx/conf.d \
    && rm -rf /usr/local/openresty/nginx/conf

# COPY ./example/conf /usr/local/openresty/nginx/conf
# COPY ./example/conf.d /etc/nginx/conf.d

WORKDIR /var/www/html/public
