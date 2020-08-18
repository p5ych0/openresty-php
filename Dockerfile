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
    && addgroup -g 82 -S www-data \
    && adduser -u 82 -D -S -h /var/cache/nginx -s /sbin/nologin -G www-data www-data \
    && openssl req -new -newkey rsa:2048 -days 3650 -nodes -x509 \
        -subj '/CN=sni-support-required-for-valid-ssl' \
        -keyout /etc/resty-auto-ssl/fallback.key \
        -out /etc/resty-auto-ssl/fallback.crt \
        && chown www-data -R /etc/resty-auto-ssl \
    && chown www-data /etc/resty-auto-ssl \
    && mkdir /var/log/nginx \
    && chown www-data:www-data /var/log/nginx \
    && chmod 0775 /var/log/nginx \
    && chown www-data:www-data -R /var/www

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
