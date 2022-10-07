FROM php:%PHP_VERSION%-fpm

# install git inside container
RUN apt update && apt install -y git

# download and set ext installer
ADD https://github.com/mlocati/docker-php-extension-installer/releases/latest/download/install-php-extensions /usr/local/bin/

# install required php exts
RUN chmod +x /usr/local/bin/install-php-extensions && \
    install-php-extensions imagick gd intl zip pcntl exif pdo_mysql

# install composer from composer image
COPY --from=composer:latest /usr/bin/composer /usr/local/bin/composer

# install node & deps
RUN apt-get install -y curl \
  && curl -sL https://deb.nodesource.com/setup_17.x | bash - \
  && apt-get install -y nodejs \
  && curl -L https://www.npmjs.com/install.sh | sh

# set www-data permissions to match default user
RUN usermod -u 1000 www-data \
    && usermod -aG staff www-data

# set www-data home
RUN mkdir -p /home/www-data \
    && chown -R www-data:www-data /home/www-data \
    && usermod -d /home/www-data www-data

