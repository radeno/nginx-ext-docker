FROM alpine:3.10

ENV NGINX_VERSION 1.17.7

# https://github.com/centminmod/centminmod/tree/master/patches/nginx

RUN set -x \
  && apk add --no-cache libatomic_ops pcre tzdata \
  && apk add --no-cache --virtual .build-deps build-base git autoconf automake openssl-dev libtool wget tar pcre-dev zlib-dev libatomic_ops-dev unzip patch linux-headers util-linux binutils \
  && addgroup -g 101 -S nginx \
  && adduser -S -D -H -u 101 -h /var/cache/nginx -s /sbin/nologin -G nginx -g nginx nginx \
  && cd /tmp \
  && wget -q http://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz \
  && tar xf nginx-${NGINX_VERSION}.tar.gz \
  && cd /tmp/nginx-${NGINX_VERSION} \
  && wget -q https://raw.githubusercontent.com/kn007/patch/master/nginx.patch -O- | patch -p1 \
  && cd /tmp \
  && git clone https://github.com/google/ngx_brotli.git \
  && cd /tmp/ngx_brotli && git submodule update --init && cd /tmp \
  && git clone https://github.com/cloudflare/zlib.git \
  && cd /tmp/zlib && make -f Makefile.in distclean && cd /tmp \
  && cd /tmp \
  # && git clone https://github.com/openresty/headers-more-nginx-module.git \
  && cd /tmp/nginx-${NGINX_VERSION} \
  && ./configure \
  --prefix=/etc/nginx \
  --sbin-path=/usr/sbin/nginx \
  --modules-path=/usr/lib/nginx/modules \
  --conf-path=/etc/nginx/nginx.conf \
  --error-log-path=/var/log/nginx/error.log \
  --http-log-path=/var/log/nginx/access.log \
  --pid-path=/var/run/nginx.pid \
  --lock-path=/var/run/nginx.lock \
  --http-client-body-temp-path=/var/cache/nginx/client_temp \
  --http-proxy-temp-path=/var/cache/nginx/proxy_temp \
  --http-fastcgi-temp-path=/var/cache/nginx/fastcgi_temp \
  --user=nginx \
  --group=nginx \
  --with-threads \
  --with-file-aio \
  --with-http_addition_module \
  --with-http_auth_request_module \
  --with-http_gunzip_module \
  --with-http_gzip_static_module \
  --with-http_realip_module \
  --with-http_ssl_module \
  --with-http_stub_status_module \
  --with-http_sub_module \
  --with-http_v2_module \
  --with-http_v2_hpack_enc \
  --with-libatomic \
  --with-zlib=/tmp/zlib \
  --add-module=/tmp/ngx_brotli \
  # --add-module=/tmp/headers-more-nginx-module \
  --with-openssl-opt="zlib no-tests enable-ec_nistp_64_gcc_128 -DCFLAGS='-march=native -O3 -flto'" \
  --with-cc-opt="-O3 -march=native -flto -fPIC -fPIE -fstack-protector-strong -Wformat -Werror=format-security -Wno-deprecated-declarations -Wno-strict-aliasing" \
  && make \
  && make install \
  && apk del .build-deps \
  && mkdir -p /var/cache/nginx \
  # forward request and error logs to docker log collector
  && ln -sf /dev/stdout /var/log/nginx/access.log \
  && ln -sf /dev/stderr /var/log/nginx/error.log \
  && cd / && rm -rf /tmp/*

STOPSIGNAL SIGTERM

CMD ["nginx", "-g", "daemon off;"]
