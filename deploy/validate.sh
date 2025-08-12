#!/usr/bin/env bash
set -euo pipefail
for i in {1..15}; do
  if curl -fsS -m 5 -o /dev/null http://127.0.0.1:3210/; then
    exit 0
  fi
  sleep 2
done
echo "Validate failed: service not ready on 3210" >&2
exit 1
