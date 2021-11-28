FROM ghcr.io/linuxserver/baseimage-alpine-nginx:3.15

ARG BUILD_DATE
ARG VERSION
ARG GRAV_RELEASE
LABEL build_version="Linuxserver.io version:- ${VERSION} Build-date:- ${BUILD_DATE}"
LABEL maintainer="TheSpad"

RUN \
  echo "**** install runtime packages ****" && \
  apk add --update --no-cache \
    busybox-suid \
    curl \
    php8-dom \
    php8-gd \
    php8-intl \
    php8-opcache \
    php8-pecl-apcu \
    php8-pecl-yaml \
    php8-redis \
    php8-tokenizer \
    unzip && \
  echo "**** install composer ****" && \
  php8 -r "copy('https://getcomposer.org/installer', 'composer-setup.php');" && \
  php8 composer-setup.php --install-dir=/usr/local/bin/composer --filename=composer && \
  echo "**** setup php opcache ****" && \
  { \
    echo 'opcache.memory_consumption=128'; \
    echo 'opcache.interned_strings_buffer=8'; \
    echo 'opcache.max_accelerated_files=4000'; \
    echo 'opcache.revalidate_freq=2'; \
    echo 'opcache.enable_cli=1'; \
  } > /etc/php8/conf.d/php-opcache.ini && \
  if [ -z ${GRAV_RELEASE+x} ]; then \
    GRAV_RELEASE=$(curl -sX GET "https://api.github.com/repos/getgrav/grav/releases/latest" \
    | awk '/tag_name/{print $4;exit}' FS='[""]'); \
  fi && \
  echo "*** Installing Grav ***" && \
  mkdir -p \
    /app/www/public && \
  curl -o \
    /tmp/grav.zip -L \
    "https://github.com/getgrav/grav/releases/download/${GRAV_RELEASE}/grav-admin-v${GRAV_RELEASE}.zip" && \
  unzip -q \
    /tmp/grav.zip -d /tmp/grav && \
  mv /tmp/grav/grav-admin/* /app/www/public/ && \
  echo "**** cleanup ****" && \
  rm -rf \
    /root/.composer \
    /root/.cache \
    /tmp/*

COPY root/ /

EXPOSE 80

VOLUME /config
