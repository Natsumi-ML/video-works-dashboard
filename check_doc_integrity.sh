#!/bin/sh
# Document Integrity Check
# 長文Markdownを分割追記で作るため、書き込み後に構造が壊れていないか機械的に確認する。
# 使い方: sh check_doc_integrity.sh SOCIAL_BASE_SYSTEM_DESIGN.md [期待する章数]
set -u
F="${1:-SOCIAL_BASE_SYSTEM_DESIGN.md}"
WANT_CH="${2:-29}"
FAIL=0
ok()   { printf "  OK   %s\n" "$1"; }
bad()  { printf "  FAIL %s\n" "$1"; FAIL=1; }

[ -f "$F" ] || { echo "no such file: $F"; exit 2; }
echo "== Document Integrity Check: $F =="

# 1. 予定した全章が存在する
n=$(grep -c '^## [0-9]' "$F")
[ "$n" -eq "$WANT_CH" ] && ok "章数 $n" || bad "章数 $n（期待 $WANT_CH）"

# 2. 見出しの欠落・重複・順序崩れ
grep -o '^## [0-9]\+' "$F" | sed 's/^## //' | awk -v w="$WANT_CH" '
  { if ($1+0 != NR) { printf "  FAIL 章番号の順序崩れ: %s 番目に %s\n", NR, $1; e=1 } }
  END { if (!e) printf "  OK   章番号 1..%s が順序どおり\n", w }'
grep -o '^## [0-9]\+' "$F" | sort | uniq -d | grep . && bad "章見出しが重複" || ok "章見出しの重複なし"
d=$(grep '^### ' "$F" | sort | uniq -d)
[ -z "$d" ] && ok "節見出しの重複なし（$(grep -c '^### ' "$F") 件）" || { echo "$d" | sed 's/^/       /'; bad "節見出しが重複"; }
grep -o '^### [0-9]\+\.[0-9]\+' "$F" | sed 's/### //' | awk -F. '
  { if ($1 != ch) { ch=$1; want=1 }
    if ($2+0 != want) { printf "  FAIL 節番号の飛び: %s.%s（期待 %s.%s）\n", $1, $2, ch, want; e=1 }
    want = $2+1 }
  END { if (!e) printf "  OK   節番号に飛びなし（%s 件）\n", NR }'

# 目次と章見出しの一致
if sed -n '/^## 目次/,/^---$/p' "$F" | grep -q '^[0-9]\+\. \['; then
  a=$(sed -n '/^## 目次/,/^---$/p' "$F" | grep -oE '^[0-9]+\. \[[^]]+\]' | sed 's/^[0-9]*\. \[//;s/\]$//')
  b=$(grep '^## [0-9]' "$F" | sed 's/^## [0-9]*\. //')
  [ "$a" = "$b" ] && ok "目次と章見出しが一致" || bad "目次と章見出しが不一致"
fi

# 3. 分割追記による重複・欠落
d=$(awk '/^```/{f=!f; next} !f && length($0)>60 && $0 !~ /^\|---/ && $0 !~ /^> \*\*/ && $0 !~ /^- \*\*/' "$F" | sort | uniq -d)
[ -z "$d" ] && ok "60字超の本文行に重複なし" || { echo "$d" | head -5 | sed 's/^/       DUP: /'; bad "本文行が重複（二重貼りの疑い）"; }
grep -o '§[0-9]\+\(\.[0-9]\+\)\?' "$F" | sed 's/§//' | sort -u > /tmp/_dic_r
{ grep -o '^## [0-9]\+' "$F" | sed 's/^## //'; grep -o '^### [0-9]\+\.[0-9]\+' "$F" | sed 's/^### //'; } | sort -u > /tmp/_dic_h
m=$(comm -23 /tmp/_dic_r /tmp/_dic_h); rm -f /tmp/_dic_r /tmp/_dic_h
[ -z "$m" ] && ok "相互参照がすべて実在する節を指す" || { echo "$m" | sed 's/^/       DANGLING: §/'; bad "存在しない節への参照"; }

# 4. code fence / Mermaid block の開閉
awk '/^```/{ if(!o){o=1; s=NR} else o=0; next } END { if(o) { printf "  FAIL 未クローズのコードブロック（L%s から）\n", s; exit 1 } else print "  OK   コードフェンスはすべて閉じている" }' "$F" || FAIL=1
mb=$(grep -c '^```mermaid' "$F")
me=$(grep -A1 '^```mermaid' "$F" | grep -c '^erDiagram\|^flowchart\|^graph\|^sequenceDiagram')
[ "$mb" -eq "$me" ] && ok "mermaid ブロック $mb 個すべてに図種の宣言がある" || bad "mermaid ブロック $mb 個中 $me 個しか宣言がない"
p=$(awk '/^```mermaid/{m=1;next} /^```$/{m=0} m && /"[^"]*\|[^"]*"/' "$F" | wc -l)
[ "$p" -eq 0 ] && ok "mermaid の引用文字列にパイプなし" || bad "mermaid の引用文字列にパイプ $p 行（GitHubで描画が崩れる）"

# 5. ファイル末尾が途中で切れていない
[ "$(tail -c 1 "$F" | od -An -c | tr -d ' ')" = "\n" ] && ok "改行で終端" || bad "末尾が改行で終わっていない"
tail -1 "$F" | grep -qE '^(\||#|-|[0-9])' && ok "最終行が文の途中ではない" || bad "最終行が途中で切れている疑い: $(tail -1 "$F" | cut -c1-40)"

# 6. git diff --check
if git rev-parse --git-dir >/dev/null 2>&1; then
  git diff --check >/dev/null 2>&1 && git diff --cached --check >/dev/null 2>&1 \
    && ok "git diff --check クリーン" || bad "git diff --check に指摘あり"
  grep -nE '^(<<<<<<<|=======|>>>>>>>)' "$F" >/dev/null && bad "コンフリクトマーカー残存" || ok "コンフリクトマーカーなし"
  # 7. 意図した Markdown 以外に変更がないこと
  other=$(git status --porcelain | awk '{print $2}' | grep -vE '\.md$' | grep -v '^check_doc_integrity.sh$')
  [ -z "$other" ] && ok "作業ツリーに .md 以外の変更なし" || { echo "$other" | sed 's/^/       /'; bad "Markdown以外に変更がある"; }
  if [ -f ml-editing-board.html ]; then
    git diff f264170 --quiet -- ml-editing-board.html 2>/dev/null \
      && ok "ml-editing-board.html は f264170 から無変更" || bad "現行実装が変更されている"
  fi
fi

echo
[ "$FAIL" -eq 0 ] && echo "== PASS ==" || echo "== FAIL =="
exit "$FAIL"
