#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 1 ]]; then
  echo "usage: $0 <xcresult-path>"
  exit 1
fi

XCRESULT="$1"
REPORT=$(xcrun xccov view --report "$XCRESULT")

APP_LINE=$(echo "$REPORT" | awk '/^OpenDisk[[:space:]]+[0-9.]+%/ {print; exit}')
if [[ -z "$APP_LINE" ]]; then
  echo "could not find OpenDisk coverage line"
  echo "$REPORT"
  exit 1
fi

APP_COVERAGE=$(echo "$APP_LINE" | awk '{gsub("%", "", $2); print $2}')

awk -v c="$APP_COVERAGE" 'BEGIN {
  if (c + 0 < 85.0) {
    printf("coverage gate failed: OpenDisk %.2f%% < 85.0%%\n", c)
    exit 1
  }
}'

echo "coverage gate passed: OpenDisk ${APP_COVERAGE}%"
