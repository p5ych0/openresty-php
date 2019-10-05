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
    procps \
    && mkdir -p /etc/resty-auto-ssl \
    && addgroup -S nginx \
    && adduser -D -S -h /var/cache/nginx -s /sbin/nologin -G nginx nginx \
    && chown nginx /etc/resty-auto-ssl

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
        unzip \
        g++ \
        cmake \
        lua \
        lua-dev \
        make \
        autoconf \
        automake \
    && /usr/local/openresty/luajit/bin/luarocks install lua-resty-auto-ssl \
    && apk del .build-deps \
    && mkdir -p /var/cache/nginx \
    && rm -rf /etc/nginx/conf.d/*

# use self signed ssl certificate to start nginx
COPY ./ssl /etc/resty-auto-ssl
# COPY ./example/nginx.conf /usr/local/openresty/nginx/conf/nginx.conf
RUN rm -rf /etc/nginx/conf.d
# COPY ./example/server.conf /etc/nginx/conf.d/server.conf

WORKDIR /var/www/html/public
