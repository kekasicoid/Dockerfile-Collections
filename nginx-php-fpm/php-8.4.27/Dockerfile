FROM php:8.4.27-fpm-trixie

# Versi Elastic APM PHP agent (mendukung PHP 7.2–8.4).
ARG ELASTIC_APM_VERSION=1.17.1

# PHP API version untuk PHP 8.4 (dipakai untuk nama file .so ekstensi APM).
ARG PHP_API_VERSION=20240924

# Pin versi nginx. Debian 13 (Trixie) menyediakan seri 1.26.x.
# Memakai pola '1.26.*' agar tetap dapat patch keamanan tanpa build gagal
# ketika revisi paket penuh (mis. 1.26.3-3+deb13u9) ditarik dari repo.
ARG NGINX_VERSION=1.26.*

# -----------------------------------------------------------------------------
# 1) System deps + runtime (nginx, supervisor) + lib untuk kompilasi ekstensi.
# -----------------------------------------------------------------------------
RUN set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends \
        "nginx=${NGINX_VERSION}" \
        supervisor \
        ca-certificates \
        curl \
        wget \
        libxml2-dev \
        libcurl4-openssl-dev \
        libzip-dev \
        libpng-dev \
        libjpeg-dev \
        libfreetype6-dev \
        libonig-dev \
    ; \
    rm -rf /var/lib/apt/lists/*

# -----------------------------------------------------------------------------
# 2) Ekstensi PHP umum (set standar yang lazim dibutuhkan aplikasi PHP).
# -----------------------------------------------------------------------------
RUN set -eux; \
    docker-php-ext-configure gd --with-freetype --with-jpeg; \
    docker-php-ext-install -j"$(nproc)" \
        mysqli \
        pdo_mysql \
        soap \
        curl \
        zip \
        gd \
        mbstring \
        bcmath \
        pcntl \
        xml

# -----------------------------------------------------------------------------
# 3) Elastic APM PHP agent (.deb). .so PHP 8.4 memakai API ${PHP_API_VERSION}.
# -----------------------------------------------------------------------------
RUN set -eux; \
    arch="$(dpkg --print-architecture)"; \
    wget -O /tmp/apm-agent-php.deb \
        "https://github.com/elastic/apm-agent-php/releases/download/v${ELASTIC_APM_VERSION}/apm-agent-php_${ELASTIC_APM_VERSION}_${arch}.deb"; \
    dpkg -i /tmp/apm-agent-php.deb || (apt-get update && apt-get -y -f install && rm -rf /var/lib/apt/lists/*); \
    rm -f /tmp/apm-agent-php.deb

# -----------------------------------------------------------------------------
# 4) Konfigurasi PHP (general) — digenerate inline agar file berdiri sendiri.
# -----------------------------------------------------------------------------
RUN set -eux; \
    { \
        echo 'memory_limit = 512M'; \
        echo 'upload_max_filesize = 64M'; \
        echo 'post_max_size = 64M'; \
        echo 'date.timezone = UTC'; \
        echo 'max_execution_time = 300'; \
        echo 'max_input_time = 300'; \
    } > /usr/local/etc/php/conf.d/zz-app.ini

# -----------------------------------------------------------------------------
# 5) Pool php-fpm (general) — listen 127.0.0.1:9000 agar cocok dengan nginx.
# -----------------------------------------------------------------------------
RUN set -eux; \
    { \
        echo '[www]'; \
        echo 'user = www-data'; \
        echo 'group = www-data'; \
        echo 'listen = 127.0.0.1:9000'; \
        echo 'pm = dynamic'; \
        echo 'pm.max_children = 50'; \
        echo 'pm.start_servers = 5'; \
        echo 'pm.min_spare_servers = 5'; \
        echo 'pm.max_spare_servers = 20'; \
        echo 'catch_workers_output = yes'; \
        echo 'decorate_workers_output = no'; \
        echo 'clear_env = no'; \
    } > /usr/local/etc/php-fpm.d/zz-app.conf

# -----------------------------------------------------------------------------
# 6) Elastic APM ini (general). Nilai server_url/service_name diisi via
#    environment/mount saat deploy; di sini cukup default minimal + extension.
# -----------------------------------------------------------------------------
RUN set -eux; \
    { \
        echo '[elastic]'; \
        echo "extension=/opt/elastic/apm-agent-php/extensions/elastic_apm-${PHP_API_VERSION}.so"; \
        echo 'elastic_apm.bootstrap_php_part_file=/opt/elastic/apm-agent-php/src/bootstrap_php_part.php'; \
        echo 'elastic_apm.enabled=true'; \
        echo 'elastic_apm.log_level=INFO'; \
    } > /usr/local/etc/php/conf.d/98-elastic-apm.ini

# -----------------------------------------------------------------------------
# 7) nginx (general) — server_block minimal yang mem-proxy .php ke php-fpm.
# -----------------------------------------------------------------------------
RUN set -eux; \
    { \
        echo 'server {'; \
        echo '    listen 80 default_server;'; \
        echo '    root /var/www/html;'; \
        echo '    index index.php index.html;'; \
        echo '    location / {'; \
        echo '        try_files $uri $uri/ /index.php?$query_string;'; \
        echo '    }'; \
        echo '    location ~ \.php$ {'; \
        echo '        include fastcgi_params;'; \
        echo '        fastcgi_pass 127.0.0.1:9000;'; \
        echo '        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;'; \
        echo '        fastcgi_read_timeout 300;'; \
        echo '    }'; \
        echo '}'; \
    } > /etc/nginx/sites-enabled/default; \
    ln -sf /dev/stdout /var/log/nginx/access.log; \
    ln -sf /dev/stderr /var/log/nginx/error.log

# -----------------------------------------------------------------------------
# 8) supervisor — jalankan php-fpm + nginx (supervisord sebagai PID 1).
# -----------------------------------------------------------------------------
RUN set -eux; \
    { \
        echo '[supervisord]'; \
        echo 'nodaemon=true'; \
        echo 'user=root'; \
        echo 'logfile=/dev/stdout'; \
        echo 'logfile_maxbytes=0'; \
        echo 'pidfile=/run/supervisord.pid'; \
        echo ''; \
        echo '[program:php-fpm]'; \
        echo 'command=/usr/local/sbin/php-fpm --nodaemonize'; \
        echo 'autostart=true'; \
        echo 'autorestart=true'; \
        echo 'priority=10'; \
        echo 'stdout_logfile=/dev/stdout'; \
        echo 'stdout_logfile_maxbytes=0'; \
        echo 'stderr_logfile=/dev/stderr'; \
        echo 'stderr_logfile_maxbytes=0'; \
        echo ''; \
        echo '[program:nginx]'; \
        echo 'command=/usr/sbin/nginx -g "daemon off;"'; \
        echo 'autostart=true'; \
        echo 'autorestart=true'; \
        echo 'priority=20'; \
        echo 'stdout_logfile=/dev/stdout'; \
        echo 'stdout_logfile_maxbytes=0'; \
        echo 'stderr_logfile=/dev/stderr'; \
        echo 'stderr_logfile_maxbytes=0'; \
    } > /etc/supervisor/conf.d/app.conf

WORKDIR /var/www/html

# -----------------------------------------------------------------------------
# 9) index.php default (phpinfo) — berguna untuk smoke test image.
#    Catatan: fungsi yang benar adalah phpinfo(), bukan phpinfp().
# -----------------------------------------------------------------------------
RUN set -eux; \
    echo '<?php echo phpinfo(); ?>' > /var/www/html/index.php


EXPOSE 80

CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/supervisord.conf"]