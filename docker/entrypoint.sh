#!/bin/dumb-init bash

set -eo pipefail

cd /app
exec bundle exec unicorn "$@"
