#!/bin/bash
# Runs every regression script (t-*.lua, except shared libraries and stubs) against
# the addon and prints each one's last line; a non-zero exit when any reports a
# problem. RPSHEET_REPO picks another checkout. Extra args: name filters.
cd "$(dirname "$0")"
fail=0
for f in $(ls t-*.lua | grep -v -E -- "-(lib|codec|ui|ui-[a-z]+|base|walk|dialog)\.lua$"); do
    if [ -n "$1" ] && ! echo "$f" | grep -q "$1"; then continue; fi
    out=$(timeout 300 bash run.sh "$f" 2>&1)
    full=$(echo "$out" | tail -1)
    last=$(echo "$full" | cut -c1-160)
    if echo "$out" | grep -q -E "^PROBLEM|^ERROR" || ! echo "$full" | grep -q -E "(^|[^0-9])0 problems"; then
        fail=1; echo "FAIL $f: $last"; echo "$out" | grep -E "^PROBLEM|^ERROR" | head -5
    else echo "ok   $f: $last"; fi
done
exit $fail
