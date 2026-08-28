# SOCIAL BASE Development Instructions

このリポジトリのUI/UXを変更する前に、必ず以下を参照してください。

## UI仕様書
- `SOCIAL_BASE_UI_IMPLEMENTATION_SPEC.md`

## 完成イメージ
- `01_home.png` — ホーム
- `02_today.png` — 今日
- `03_alldata.png` — 動画一覧 + 進行トラック統合
- `04_team.png` — チーム負荷
- `05_calendar.png` — 投稿カレンダー
- `06_client.png` — クライアント管理

- ## レスポンシブ仕様
- `SOCIAL_BASE_TODAY_RESPONSIVE_SPEC.md`

## 正式ロゴ
- `rogo.png`

## 重要ルール
- 仕様書と参考画像を確認せずにUIを独自判断で再設計しない。
- 既存機能を壊さず、段階的に改修する。
- 色、ステータス、文言、レスポンシブ仕様は仕様書を正とする。
- 「進行トラック」は独立ページにせず「動画一覧」へ統合する。
- 「クライアント管理」は社員のみに表示する。
- スマホ版はPC版の単純縮小にしない。
- 正式ロゴは `rogo.png` のデザインを基準にする。

## 実装前
1. 現在のコード構造を確認する。
2. `SOCIAL_BASE_UI_IMPLEMENTATION_SPEC.md` を読む。
3. 該当画面の参考画像を確認する。
4. 変更計画を簡潔に整理してから実装する。

## 実装後
- `SOCIAL_BASE_UI_IMPLEMENTATION_SPEC.md` の Acceptance Criteria を使って自己チェックする。
