# The Bean factory

## Requirements

- [Docker engine](https://docs.docker.com/engine/install/)
- [uv](https://docs.astral.sh/uv/)
- [GNU make](https://www.gnu.org/software/make/)
- [GNU bash](https://www.gnu.org/software/bash/)
- [Git](https://git-scm.com/install/)
- Standard *nix utilities

This was written and tested on `Ubuntu 26.04 LTS` on an x64 CPU.\
I have not attempted to make this work on ARM - and likely won't bother.\
PRs for ARM build pipelines are welcome.

## Getting started

```sh
# Installs development dependencies
make init
# Runs the Bean factory components in docker containers
make run
```
