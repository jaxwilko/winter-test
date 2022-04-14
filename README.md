# Winter Test

This project offers a simple way to test branches against specific php versions.

### Requirements

You must have `docker`, `docker-compose` and a bash v4 compatible shell installed.

### Installation

```shell
git clone git@github.com:jaxwilko/winter-test.git
```

### Execution

You can specify the branch to pull via an argument or you will be prompted to upon execution.

The PHP version defaults to `8.0`, but can be specificed via the `-p` flag.

To run a tests against php 8.1 & the develop branch:
```shell
./main.sh -p 8.1 -b develop
```
To run a tests against php 8.0 & the 1.1 branch:
```shell
./main.sh -p 8.0 -b 1.1
```
To run tests against the default PHP version and be prompted for the branch
```shell
./main.sh
```