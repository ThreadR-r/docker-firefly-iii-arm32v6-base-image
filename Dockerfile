#ThreadR

FROM arm32v6/php:7.4.1-fpm-alpine
COPY qemu-arm-static /usr/bin/
ENV COMPOSER_ALLOW_SUPERUSER=1

RUN apk add --no-cache --update libmemcached-libs zlib

RUN set -xe && \
    #Go tmp dir
    cd /tmp/ && \
    apk add --no-cache --update --virtual .phpize-deps $PHPIZE_DEPS && \
    apk add --no-cache --update --virtual .memcached-deps zlib-dev libmemcached-dev cyrus-sasl-dev && \
    apk add --no-cache --update --virtual .php-ext-deps zlib-dev openldap-dev libpng-dev postgresql-dev sqlite-dev icu-dev libmemcached-dev && \
    #igbinary
    pecl install igbinary && \
    #memcached
    ( \
        pecl install --nobuild memcached && \
        cd "$(pecl config-get temp_dir)/memcached" && \
        phpize && \
        ./configure --enable-memcached-igbinary && \
        make -j$(nproc) && \
        make install && \
        cd /tmp/ \
    ) && \
    docker-php-ext-enable igbinary memcached && \
    rm -rf /tmp/* && \
    docker-php-ext-install bcmath ldap gd pdo_pgsql pdo_sqlite pdo_mysql intl opcache && \
    apk del .memcached-deps .phpize-deps .php-ext-deps && \
    apk add --no-cache libpq libpng libldap icu-libs

RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer && \
    composer global require hirak/prestissimo --no-plugins --no-scripts && \
	cp /usr/local/etc/php/php.ini-production /usr/local/etc/php/php.ini && \
    sed -i 's/max_execution_time = 30/max_execution_time = 600/' /usr/local/etc/php/php.ini && \
    sed -i 's/memory_limit = 128M/memory_limit = 512M/' /usr/local/etc/php/php.ini
