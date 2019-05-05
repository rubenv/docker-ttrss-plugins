FROM alpine:3.9

ARG VER=master

RUN apk add --update nginx s6 php7-fpm php7-cli php7-curl php7-gd php7-json php7-dom php7-pcntl php7-posix php7-intl php7-session php7-opcache \
  php7-pgsql php7-mysqli php7-mcrypt php7-pdo php7-pdo_pgsql php7-pdo_mysql php7-mbstring php7-fileinfo ca-certificates && \
  rm -rf /var/cache/apk/*

# add ttrss as the only nginx site
ADD ttrss.nginx.conf /etc/nginx/nginx.conf

# Download plugins
ADD https://github.com/dasmurphy/tinytinyrss-fever-plugin/archive/master.tar.gz /var/www/plugins/
ADD https://github.com/levito/tt-rss-feedly-theme/archive/master.tar.gz /var/www/themes/

# install ttrss and patch configuration
WORKDIR /var/www
RUN apk add --update --virtual build-dependencies curl tar \
    && curl -SL https://git.tt-rss.org/git/tt-rss/archive/${VER}.tar.gz | tar xzC /var/www --strip-components 1 \
    && tar xzvpf /var/www/plugins/master.tar.gz --strip-components=1 -C /var/www/plugins/ tinytinyrss-fever-plugin-master/fever && rm /var/www/plugins/master.tar.gz \
    && tar xzvpf /var/www/themes/master.tar.gz --strip-components=1 -C /var/www/themes/ tt-rss-feedly-theme-master/feedly tt-rss-feedly-theme-master/feedly.css && rm /var/www/themes/master.tar.gz \
    && apk del build-dependencies \
    && rm -rf /var/cache/apk/* \
    && cp config.php-dist config.php \
    && chown nobody:nginx -R /var/www

# expose only nginx HTTP port
EXPOSE 80

# complete path to ttrss
ENV SELF_URL_PATH http://localhost

# expose default database credentials via ENV in order to ease overwriting
ENV DB_NAME ttrss
ENV DB_USER ttrss
ENV DB_PASS ttrss

# always re-configure database with current ENV when RUNning container, then monitor all services
ADD configure-db.php /configure-db.php
ADD s6/ /etc/s6/

CMD php7 /configure-db.php && exec s6-svscan /etc/s6/
