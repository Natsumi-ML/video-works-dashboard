#!/bin/sh
# ml-editing-board.html -> _preview_test.html (window.claude stub inserted before #root)
set -e
cd "$(dirname "$0")"
L=$(grep -n '^<div id="root">' ml-editing-board.html | cut -d: -f1)
head -$((L-1)) ml-editing-board.html > .pv.tmp
echo '<script>window.claude={use:function(){return Promise.resolve({publish:function(){return Promise.resolve(true)}})}};</script>' >> .pv.tmp
tail -n +$L ml-editing-board.html >> .pv.tmp
mv .pv.tmp _preview_test.html
echo "rebuilt _preview_test.html (stub before line $L)"
