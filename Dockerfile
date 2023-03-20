# Для начала указываем исходный образ, он будет использован как основа
FROM php:8.2.4-fpm-bullseye

LABEL version="1.1" \
author="WildFox24.ru" \
e-mail="klek07@ya.ru" \
created="20.12.2022" \
updateed="17.03.2023"

# RUN выполняет идущую за ней команду в контексте нашего образа.
# В данном случае мы установим некоторые зависимости и модули PHP.
# Для установки модулей используем команду docker-php-ext-install.
# На каждый RUN создается новый слой в образе, поэтому рекомендуется объединять команды.
RUN apt-get update && apt-get install -y \
        curl \
        wget \
        git \
        libfreetype6-dev \
        libonig-dev \
        libpq-dev \
        libjpeg62-turbo-dev \
        libmcrypt-dev \
        libpng-dev \
        libzip-dev \
        libxml2-dev \
        libaio1\
    && rm -f /var/lib/apt/lists/*. \
    #&& pecl install mcrypt-1.0.5  \
    && docker-php-ext-install -j$(nproc) iconv mbstring mysqli pgsql pdo_mysql pdo_pgsql zip soap \
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install -j$(nproc) gd 
    #&& docker-php-ext-enable mcrypt

# Куда же без composer'а.
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# Добавим свой php.ini, можем в нем определять свои значения конфига
COPY php.ini /usr/local/etc/php/conf.d/40-custom.ini
COPY instantclient/ /opt/oracle/instantclient/
COPY ld.so.conf.d/oracle.conf /etc/ld.so.conf.d/oracle.conf
RUN ldconfig
COPY oci8-3.2.1/ /root/tmp/
RUN cd /root/tmp \
&& phpize \
&& ./configure -with-oci8=shared,instantclient,/opt/oracle/instantclient/ \
&& make install

EXPOSE 9000

# Указываем рабочую директорию для PHP
WORKDIR /var/www

# Запускаем контейнер
# Из документации: The main purpose of a CMD is to provide defaults for an executing container. These defaults can include an executable,
# or they can omit the executable, in which case you must specify an ENTRYPOINT instruction as well.
CMD ["php-fpm"]
