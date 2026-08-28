# SOCIAL BASE Development Instructions

このリポジトリのUI/UXを変更する前に、必ず以下を参照してください。

## UI仕様書
- `docs/ui/SOCIAL_BASE_UI_IMPLEMENTATION_SPEC.md`

## 完成イメージ
- `docs/ui/reference/01-home.png`
- `docs/ui/reference/02-today.png`
- `docs/ui/reference/03-videos.png`
- `docs/ui/reference/04-team-load.png`
- `docs/ui/reference/05-calendar.png`
- `docs/ui/reference/06-client-management.png`

## 正式ロゴ
- `docs/ui/reference/social-base-logo-reference.png`

## 重要ルール
- 仕様書と参考画像を確認せずにUIを独自判断で再設計しない。
- 既存機能を壊さず、段階的に改修する。
- 色、ステータス、文言、レスポンシブ仕様は仕様書を正とする。
- 「進行トラック」は独立ページにせず「動画一覧」へ統合する。
- 「クライアント管理」は社員のみに表示する。
- スマホ版はPC版の単純縮小にしない。
- 正式ロゴは `social-base-logo-reference.png` のデザインを基準にする。

## 実装前
1. 既存コード構造を確認する。
2. UI仕様書を読む。
3. 該当画面の参考画像を確認する。
4. 変更計画を簡潔に整理してから実装する。

## 実装後
- `SOCIAL_BASE_UI_IMPLEMENTATION_SPEC.md` の Acceptance Criteria を使って自己チェックする。
