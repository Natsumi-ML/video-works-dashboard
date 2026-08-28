#!/bin/sh
# Visual QA fixture for 02_today.png comparison.
# ml-editing-board.html -> _qa_today.html
#  - state JSON is replaced by a QA fixture (reference-like counts/titles)
#  - ME preset to a 社員, window.claude stubbed, view forced to "today"
# Production file and save logic are untouched; this output is QA-only.
set -e
cd "$(dirname "$0")"
SRC=ml-editing-board.html
OUT=_qa_today.html

# アプリの TODAY は Date.now()+9h（Asia/Tokyo）。同じ式で日付を出す
T=$(date -u -d "+9 hours" +%F)
M=$(date -u -d "+9 hours" +%Y-%m)
Tm1=$(date -u -d "+9 hours -1 day" +%F)
Tm2=$(date -u -d "+9 hours -2 day" +%F)
Tm3=$(date -u -d "+9 hours -3 day" +%F)
Tm4=$(date -u -d "+9 hours -4 day" +%F)
Tp1=$(date -u -d "+9 hours +1 day" +%F)
Tp2=$(date -u -d "+9 hours +2 day" +%F)
Tp3=$(date -u -d "+9 hours +3 day" +%F)
Tp4=$(date -u -d "+9 hours +4 day" +%F)
DR='"material":"https://drive.google.com/drive/folders/qa-m","review":"https://drive.google.com/drive/folders/qa-r"'

STATE=$(cat <<EOF
<script id="state" type="application/json">{"version":1,"seeded":false,"rows":[
{"id":"qa-1","contractId":"hiro-v","client":"ヒロダクト工業","kind":"動画","month":"$M","title":"新築マンション案内動画","editor":"ゆかり","status":"編集中","planned":"$Tm2","due":"$Tm4","postedAt":null,"trans":{},"actor":"","dateLocked":false,"squeezed":false,"url":"","note":"","updatedAt":{}},
{"id":"qa-2","contractId":"metro-v","client":"メトロ自動車","kind":"動画","month":"$M","title":"代表メッセージ動画","editor":"りりか","status":"確認中","planned":"$Tm1","due":"$Tm3","postedAt":null,"trans":{},"actor":"","dateLocked":false,"squeezed":false,"url":"","note":"","updatedAt":{}},
{"id":"qa-3","contractId":"kaki-v","client":"柿本商会","kind":"動画","month":"$M","title":"内覧ツアー動画（A棟）","editor":"ゆかり","status":"要修正","revisionNote":"テロップの表記を修正してください。","planned":"$T","due":"$T","postedAt":null,"trans":{},"actor":"","dateLocked":false,"squeezed":false,"url":"","note":"","updatedAt":{}},
{"id":"qa-4","contractId":"assist-v","client":"アシストタクシー","kind":"動画","month":"$M","title":"夏のキャンペーン告知動画","editor":"りりか","status":"編集中","planned":"$T","due":"$T","postedAt":null,"trans":{},"actor":"","dateLocked":false,"squeezed":false,"url":"","note":"","updatedAt":{}},
{"id":"qa-5","contractId":"ncn-v","client":"NCN","kind":"動画","month":"$M","title":"製品紹介動画（新モデル）","editor":"りりか","status":"未着手","planned":"$T","due":"$T","postedAt":null,"trans":{},"actor":"","dateLocked":false,"squeezed":false,"url":"","note":"","updatedAt":{}},
{"id":"qa-6","contractId":"sbs-v","client":"SBSネクサード","kind":"動画","month":"$M","title":"新商品紹介ショート動画","editor":"つかさ","status":"編集中","planned":"$T","due":"$T","postedAt":null,"trans":{},"actor":"","dateLocked":false,"squeezed":false,"url":"","note":"","updatedAt":{}},
{"id":"qa-7","contractId":"kino-v","client":"木下テーブルテニスクラブ","kind":"動画","month":"$M","title":"姿勢改善ストレッチ動画","editor":"りりか","status":"投稿待ち","planned":"$T","due":"$T","postedAt":null,"trans":{},"actor":"","dateLocked":false,"squeezed":false,"url":"","note":"","updatedAt":{}},
{"id":"qa-8","contractId":"grace-v","client":"グレースホールディングス","kind":"動画","month":"$M","title":"成功事例インタビュー動画","editor":"ゆかり","status":"確認中","planned":"$T","due":"$T","postedAt":null,"trans":{},"actor":"","dateLocked":false,"squeezed":false,"url":"","note":"","updatedAt":{}},
{"id":"qa-9","contractId":"ibako-v","client":"茨城交通","kind":"動画","month":"$M","title":"","editor":"つかさ","status":"未着手","planned":"$Tp3","due":"$Tp1","postedAt":null,"trans":{},"actor":"","dateLocked":false,"squeezed":true,"url":"","note":"","updatedAt":{}},
{"id":"qa-10","contractId":"nano-v","client":"なの花交通バス","kind":"動画","month":"$M","title":"","editor":"りりか","status":"未着手","planned":"$Tp4","due":"$Tp2","postedAt":null,"trans":{},"actor":"","dateLocked":false,"squeezed":true,"url":"","note":"","updatedAt":{}}
],"months":{},"clients":{"NCN":{$DR},"SBSネクサード":{$DR},"木下テーブルテニスクラブ":{$DR},"グレースホールディングス":{$DR},"柿本商会":{$DR},"茨城交通":{$DR},"ヒロダクト工業":{$DR},"メトロ自動車":{$DR}},"notes":{"$T":{"text":"・柿本商会の修正指示を午前中に対応すること。\n・新商品紹介ショートは撮影2件 15:00〜\n・メトロ自動車の代表挨拶はナレーション収録予定。\n・17:00〜 チーム定例ミーティング @会議室B"}},"maintenance":false,"lastUpdated":"${T}T00:00:00.000Z"}</script>
EOF
)
# fixture JSON must stay one line for the state <script>
STATE=$(printf '%s' "$STATE" | tr -d '\n')

LS=$(grep -n '^<script id="state"' $SRC | cut -d: -f1)
LR=$(grep -n '^<div id="root">' $SRC | cut -d: -f1)

head -$((LS-1)) $SRC > $OUT
printf '%s\n' "$STATE" >> $OUT
sed -n "$((LS+1)),$((LR-1))p" $SRC >> $OUT
printf '%s\n' '<script>try{localStorage.clear();localStorage.setItem("mlboard.me",JSON.stringify("なつみ"));}catch(e){}window.claude={use:function(){return Promise.resolve({publish:function(){return Promise.resolve(true)}})}};</script>' >> $OUT
tail -n +$LR $SRC >> $OUT
printf '%s\n' '<script>VIEW="today";SELECTED=null;POP=false;render();window.scrollTo(0,0);</script>' >> $OUT
echo "built $OUT (state line $LS, fixture date $T)"
