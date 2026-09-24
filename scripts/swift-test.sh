#!/bin/bash
# Runs the Swift unit tests (tests/LucidTests, Swift Testing).
#
# With only the Command Line Tools installed (no Xcode), SwiftPM's default
# build system does not find the Swift Testing macro plugin, which the CLT ship
# in a "testing" subfolder; pass its path explicitly. Extra arguments are
# forwarded to `swift test` (e.g. --filter OutlineParserTests).
set -euo pipefail
cd "$(dirname "$0")/.."

args=()
CLT_TESTING_PLUGINS=/Library/Developer/CommandLineTools/usr/lib/swift/host/plugins/testing
if [[ "$(xcode-select -p 2>/dev/null)" == /Library/Developer/CommandLineTools* && -d "$CLT_TESTING_PLUGINS" ]]; then
  args=(-Xswiftc -plugin-path -Xswiftc "$CLT_TESTING_PLUGINS")
fi

swift test ${args[@]+"${args[@]}"} "$@"
