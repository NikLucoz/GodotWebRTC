#!/bin/sh
echo -ne '\033c\033]0;WebRTC\a'
base_path="$(dirname "$(realpath "$0")")"
"$base_path/WebRTC.x86_64" "$@"
