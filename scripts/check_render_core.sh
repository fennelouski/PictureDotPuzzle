#!/bin/bash
set -euo pipefail
repo_root="$(cd "$(dirname "$0")/.." && pwd)"
test_dir="$(mktemp -d /tmp/circles-render-tests.XXXXXX)"
trap 'rm -rf "$test_dir"' EXIT
xcrun --sdk macosx clang -std=c11 -Wall -Wextra -Werror -I "$repo_root/Picture Dot Puzzle" "$repo_root/Picture Dot Puzzle/PDPRenderCore.c" "$repo_root/Tests/RenderCoreTests.c" -framework CoreGraphics -framework Foundation -o "$test_dir/render-tests"
"$test_dir/render-tests"
