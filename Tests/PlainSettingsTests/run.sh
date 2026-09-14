#!/bin/sh
set -eu

script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
repo_root=$(dirname "$(dirname "$script_dir")")
test_binary=$(mktemp "${TMPDIR:-/tmp}/PlainSettingsTests.XXXXXX")
trap 'rm -f "$test_binary"' EXIT

xcrun swiftc \
    "$repo_root/XPCService/PlainSettings.swift" \
    "$script_dir/main.swift" \
    -o "$test_binary"
"$test_binary"
