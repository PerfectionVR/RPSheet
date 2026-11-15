#!/bin/bash
# Runs a Lua script of this folder against the addon in a fake game environment.
# usage: run.sh script.lua [extra args]
# The addon is the folder above this one; RPSHEET_REPO picks another checkout.
# tests/local.cfg (not in the repository) says where the interpreter and a copy of
# the Ace3 libraries are on this machine: see tests/README.md.
PAD="$(cd "$(dirname "$0")" && pwd -W 2>/dev/null || pwd)"
WT="${RPSHEET_REPO:-$(cd "$PAD/.." && pwd -W 2>/dev/null || pwd)}"
[ -f "$PAD/local.cfg" ] && . "$PAD/local.cfg"
export RPSHEET_LUA_DLL="${RPSHEET_LUA_DLL:-$LUA_DLL}"
export RPSHEET_ACE_LIBS="${RPSHEET_ACE_LIBS:-$ACE_LIBS}"
# The three libraries the fake game loads for real are copied once from the Ace3 copy.
LIBS="$PAD/.cache/libs"
if [ ! -f "$LIBS/LibStub.lua" ]; then
    mkdir -p "$LIBS"
    IFS=';' read -ra roots <<< "$WT/Libs;$RPSHEET_ACE_LIBS"
    for root in "${roots[@]}"; do
        if [ -f "$root/LibStub/LibStub.lua" ] && [ -f "$root/AceConfig-3.0/AceConfigRegistry-3.0/AceConfigRegistry-3.0.lua" ]; then
            cp "$root/LibStub/LibStub.lua" "$root/CallbackHandler-1.0/CallbackHandler-1.0.lua" "$root/AceConfig-3.0/AceConfigRegistry-3.0/AceConfigRegistry-3.0.lua" "$LIBS/"
            break
        fi
    done
    [ -f "$LIBS/LibStub.lua" ] || { echo "ERROR: no copy of the Ace3 libraries found: set ACE_LIBS in tests/local.cfg"; exit 1; }
fi
python "$PAD/runlua.py" "$PAD/$1" "$WT" "$LIBS" "$PAD" "${@:2}" 2>&1
