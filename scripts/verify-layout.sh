#!/bin/sh
set -eu

fail() {
  printf '%s\n' "layout check failed: $*" >&2
  exit 1
}

check_dir() {
  [ -d "$1" ] || fail "missing directory: $1"
}

check_link() {
  path="$1"
  target="$2"
  [ -L "$path" ] || fail "missing symlink: $path"
  actual="$(readlink "$path")"
  [ "$actual" = "$target" ] || fail "symlink $path -> $actual (expected $target)"
}

check_dir runtime
check_dir runtime/kernel
check_dir runtime/contracts
check_dir runtime/blocks
check_dir substrate
check_dir system-image
check_dir surfaces
check_dir artifacts

check_link src runtime/kernel
check_link blocks runtime/blocks
check_link demo surfaces
check_link deploy system-image/deploy
check_link packages substrate

printf '%s\n' "ok layout"
