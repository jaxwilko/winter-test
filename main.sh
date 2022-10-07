#!/usr/bin/env bash

say() {
    echo -e "==> \033[0;33m$1\033[0m"
}

error() {
    echo -e "\033[0;31m$1\033[0m"
}

suppress_run() {
    local COMMAND="$*"

    if $VERBOSE; then
        "$@"
    else
        "$@" > /dev/null 2>&1
    fi

    EXIT_CODE=$?

    if [ ! $EXIT_CODE -eq 0 ]; then
        error "Command ${COMMAND} failed, exiting..."
        if $DOCKER_RUNNING; then
            error "Shutting down docker..."
            suppress_run docker compose down -v
        fi
        exit 1
    fi
}

usage() {
    cat << NOTICE
    OPTIONS
    -h                show this message
    -v                print verbose info
    -p [php-version]  specify a php version
    -b [branch]       specify a branch to test

    Supported PHP Versions:
    8.1
    8.0 [default]
    7.4
NOTICE
}

VERBOSE=false
DOCKER_RUNNING=false
PHP_VERSION="8.0"
PHP_VERSIONS="8.1 8.0 7.4"
BRANCH=""

while getopts hvp:b: opts; do
    case ${opts} in
        h) usage && exit 0 ;;
        v) VERBOSE=true ;;
        b) BRANCH=${OPTARG} ;;
        p) PHP_VERSION=${OPTARG} ;;
        *);;
    esac
done

if [ -z "$(echo "$PHP_VERSIONS" | grep -w "$PHP_VERSION")" ]; then
    error "Unsupported php version '${PHP_VERSION}'"
    exit 1
fi

BRANCH_NAMES=$(git ls-remote --heads git@github.com:wintercms/winter.git | awk '{print $2}' | cut -d/  -f3-)

if [ -d "./dist" ]; then
    rm -rf "./dist"
fi

if [ -n "$BRANCH" ]; then
    if [ -z "$(echo "$BRANCH_NAMES" | grep -w "$BRANCH")" ]; then
        error "Branch not found on github, exiting..."
        exit 1
    fi

    say "Cloning \033[0;34mwinter\033[0m@\033[0;32m${BRANCH}\033[0;33m into dist..."
    suppress_run git clone --depth 1 -b "${BRANCH}" git@github.com:wintercms/winter.git dist
else

    say "Fetching available branches from github..."
    INDEX=0

    declare -A BRANCHES

    for BRANCH in $BRANCH_NAMES
    do
      echo -e "\033[0;32m$INDEX\033[0m: $BRANCH"
      BRANCHES[$INDEX]="$BRANCH"
      ((INDEX=INDEX+1))
    done

    say "What branch do you want to test? [number]"
    read -r BRANCH

    if [ -z "${BRANCHES[$BRANCH]}" ]; then
        error "Invalid input, please try again."
        exit 1
    fi

    say "Cloning \033[0;34mwinter\033[0m@\033[0;32m${BRANCHES[$BRANCH]}\033[0;33m into dist..."
    suppress_run git clone --depth 1 -b "${BRANCHES[$BRANCH]}" git@github.com:wintercms/winter.git dist
fi

say "Generating docker file..."
cp "./.docker/template.Dockerfile" "./.docker/Dockerfile"
sed -i "s/\%PHP_VERSION\%/${PHP_VERSION}/g" "./.docker/Dockerfile"

DOCKER_RUNNING=true
say "Booting docker..."
suppress_run docker compose up -d

say "Composer install..."
suppress_run docker compose run --user www-data web composer install --no-interaction

say "NPM install..."
suppress_run docker compose run --user www-data web npm i

say "Run winter:env..."
suppress_run docker compose run --user www-data web ./artisan winter:env

say "Setting .env file..."
cat > ./dist/.env <<EnvFile
APP_DEBUG=true
APP_URL=http://winter.text/
APP_KEY=
APP_ENV=testing

DB_CONNECTION=mysql
DB_HOST=mysql_server
DB_PORT=3306
DB_DATABASE=winter
DB_USERNAME=root
DB_PASSWORD=Password1

DB_USE_CONFIG_FOR_TESTING=true
EnvFile

say "Run winter:up..."
suppress_run docker compose run --user www-data web ./artisan winter:up

say "Running tests..."
docker compose run --user www-data web ./artisan winter:test

say "Killing docker..."
suppress_run docker compose down -v
