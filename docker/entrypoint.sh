#!/bin/sh
set -eu

umask "${UMASK:-022}"
mkdir -p /opt/openlist/data
exec /opt/openlist/openlist server --data /opt/openlist/data --no-prefix
